//
//  Upload.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AVFoundation
import Combine
import AppKit
import SwiftUI

class Upload: NSObject, AVAssetWriterDelegate {
    
    let assetWriter: AVAssetWriter
    let audioWriterInput: AVAssetWriterInput
    let videoWriterInput: AVAssetWriterInput
    
    weak private var recordingManager: RecordingManager?
    private var supabase: Supabase
    private var webAppVideoUrl: URL
    private lazy var playlistState = IndexFileState()
    private lazy var segmentIndex = 0
    private let videoUUID: String
    
    init(recordingManager: RecordingManager?, supabase: Supabase, videoUUID: String) {
        // Create the asset writer
        self.assetWriter = AVAssetWriter(contentType: UTType(outputContentType.rawValue)!)
        
        // Create the asset writer inputs
        self.audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
        self.videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        audioWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.mediaTimeScale = segmentTimescale
        
        self.recordingManager = recordingManager
        self.supabase = supabase
        self.videoUUID = videoUUID
        
        self.webAppVideoUrl = URL(string: Bundle.main.object(forInfoDictionaryKey: "WEB_APP_URL") as! String)!.appendingPathComponent("v")
        
        super.init()
    }
    
    func setup() throws {
        if !assetWriter.canAdd(audioWriterInput) { throw RuntimeError("Can't add audio writer input to AssetWriter") }
        if !assetWriter.canAdd(videoWriterInput) { throw RuntimeError("Can't add video writer input to AssetWriter") }
        assetWriter.add(audioWriterInput)
        assetWriter.add(videoWriterInput)
        
        // Configure the asset writer for writing data in fragmented MPEG-4 format.
        assetWriter.shouldOptimizeForNetworkUse = true
        assetWriter.outputFileTypeProfile = outputFileTypeProfile
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: Double(segmentDuration), preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = startTimeOffset
        assetWriter.delegate = self
    }
    
    func stop(_ cleanup: Bool = false){
        audioWriterInput.markAsFinished()
        videoWriterInput.markAsFinished()
        
        if assetWriter.status == .completed {
            return
        }
        
        assetWriter.finishWriting { [weak self] in
            guard let self = self else {
                return
            }
            
            if cleanup {
                self.supabase.cleanup(uuid: self.videoUUID)
                return
            }
            
            if self.assetWriter.status == .completed {
                // generate playlist file
                let finalPlaylist = generateFullPlaylist(state: self.playlistState)
                guard let data = finalPlaylist.data(using: .utf8) else {
                    print("Failed to generate full playlist file. Cleaning up.")
                    relay(self.recordingManager, newState: .error)
                    self.supabase.cleanup(uuid: self.videoUUID)
    
                    return
                }
                
                self.uploadPlaylistFile(data)
            }
        }
    }
    
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        let isInitializationSegment: Bool
        
        switch segmentType {
        case .initialization:
            isInitializationSegment = true
        case .separable:
            isInitializationSegment = false
        @unknown default:
            print("Skipping segment with unrecognized type \(segmentType)")
            return
        }
        
        let segment = Segment(index: segmentIndex, data: segmentData, isInitializationSegment: isInitializationSegment, report: segmentReport)
        let segmentFileName = segment.fileName(forPrefix: segmentFileNamePrefix)
        
        uploadSegmentFile(segment, segmentFileName)
        
        playlistState = updatePlaylistForSegment(state: playlistState, segment: segment)
        
        segmentIndex += 1
    }
    
    private func uploadSegmentFile(_ segment: Segment, _ segmentFileName: String){
        do {
            try self.supabase.uploadVideoFile(uuid: videoUUID, filename: segmentFileName, data: segment.data){ [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(_):
                    print("Successfuly uploaded segment to s3: \(self.videoUUID)/\(segmentFileName)")
                case .failure(let error):
                    print("Error uploading segment: \(error.localizedDescription)")
                    self.stop(true)
                    relay(self.recordingManager, newState: .error)
                }
            }
        }catch{
            print("Runtime error when uploading segment: \(error.localizedDescription). Cleaning up.")
            self.stop(true)
            relay(self.recordingManager, newState: .error)
        }
    }
    
    private func uploadPlaylistFile(_ data: Data) {
        do {
            try self.supabase.uploadVideoFile(uuid: self.videoUUID, filename: indexFileName, data: data) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(_):
                    print("Successfuly uploaded index file to s3: \(self.videoUUID)/\(indexFileName)")
                    relay(self.recordingManager, newState: .finished(self.webAppVideoUrl.appendingPathComponent(self.videoUUID).absoluteString, self.videoUUID))
                    
                    do {
                        try self.supabase.uploadThumbnailFile(uuid: self.videoUUID, filename: screenshotFileName){ result in
                            switch result {
                            case .success(_):
                                print("Successfully uploaded thumbnail: \(self.videoUUID)/\(screenshotFileName)")
                            case .failure(let error):
                                print("Failed to upload thumbnail for video: \(error.localizedDescription)")
                            }
                            return
                        }
                    }catch{
                        print("Runtime error when uploading thumbnail for video: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("Error uploading index file: \(error.localizedDescription)")
                    relay(self.recordingManager, newState: .error)
                    self.supabase.cleanup(uuid: self.videoUUID)
                }
            }
        }catch {
            print("Error when uploading playlist file: \(error.localizedDescription). Cleaning up.")
            relay(self.recordingManager, newState: .error)
            self.supabase.cleanup(uuid: self.videoUUID)
        }
    }
}
