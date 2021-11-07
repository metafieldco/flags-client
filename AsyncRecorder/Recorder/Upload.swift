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

    private var webAppVideoUrl: URL?
    
    private let supabase: Supabase
    private let recordingManager: RecordingManager
    
    private lazy var playlistState = IndexFileState()
    private lazy var segmentIndex = 0
    private lazy var videoUUID = UUID().uuidString.lowercased()
    
    init(recordingManager: RecordingManager) {
        // The following steps check env vars
        self.supabase = Supabase()
        
        // Create the asset writer
        self.assetWriter = AVAssetWriter(contentType: UTType(outputContentType.rawValue)!)
        
        // Create the asset writer inputs
        self.audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
        self.videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        audioWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.mediaTimeScale = segmentTimescale
        
        self.recordingManager = recordingManager
        
        super.init()
    }
    
    func setup() throws {
        guard let tmp = Bundle.main.object(forInfoDictionaryKey: "WEB_APP_VIDEO_URL") as? String, !tmp.isEmpty else {
            throw RuntimeError("WEB_APP_VIDEO_URL not found in the environment.")
        }
        guard let url = URL(string: tmp) else {
            throw RuntimeError("WEB_APP_VIDEO_URL not a valid URL")
        }
        webAppVideoUrl = url
        
        do {
            try supabase.setup()
        }catch {
            throw error
        }
        
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
        
        assetWriter.finishWriting {
            if cleanup {
                self.supabase.cleanup(uuid: self.videoUUID)
                return
            }
            if self.assetWriter.status == .completed {
                // upload the playlist file + show video in browser
                let finalPlaylist = generateFullPlaylist(state: self.playlistState)
                guard let data = finalPlaylist.data(using: .utf8) else {
                    print("Failed to generate full playlist file. Cleaning up.")
                    relay(self.recordingManager, newState: .error)
                    self.supabase.cleanup(uuid: self.videoUUID)
    
                    return
                }
                do {
                    try self.supabase.uploadFile(uuid: self.videoUUID, filename: indexFileName, data: data, finish: self.handleIndexFileUpload)
                }catch {
                    print("Error when uploading playlist file: \(error.localizedDescription). Cleaning up.")
                    relay(self.recordingManager, newState: .error)
                    self.supabase.cleanup(uuid: self.videoUUID)
                }
            }
        }
    }
    
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        let isInitializationSegment: Bool
        
        print("receieved segment: \(Date().description)")
        
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
        
        do {
            try self.supabase.uploadFile(uuid: videoUUID, filename: segmentFileName, data: segment.data, finish: handleSegmentUploadResponse)
        }catch{
            print("Runtime error when uploading segment: \(error.localizedDescription). Cleaning up.")
            self.stop(true)
            relay(self.recordingManager, newState: .error)
        }
        
        playlistState = updatePlaylistForSegment(state: playlistState, segment: segment)
        
        segmentIndex += 1
    }
    
    private func handleSegmentUploadResponse(result: Result<FileUploadSuccess, SupabaseError>) {
        switch result {
        case .success(let resp):
            print("Successfuly uploaded segment to s3: \(resp.key)")
        case .failure(let error):
            print("Error uploading segment: \(error.localisedDescription())")
            self.stop(true)
            relay(self.recordingManager, newState: .error)
        }
    }
    
    private func handleIndexFileUpload(result: Result<FileUploadSuccess, SupabaseError>) {
        switch result {
        case .success(let resp):
            print("Successfuly uploaded index file to s3: \(resp.key). Well done Archie ...")
            relay(self.recordingManager, newState: .finished(self.webAppVideoUrl!.appendingPathComponent(self.videoUUID).absoluteString, self.videoUUID))
            
            do {
                try supabase.insertVideoRecord(uuid: self.videoUUID) { result in
                    switch result {
                    case .success(_):
                        print("Successfully inserted video record.")
                    case .failure(let error):
                        print("Failed to insert video record for video: \(error.localizedDescription)")
                    }
                    return
                }
            }catch{
                print("Runtime error when inserting video record for video: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Error uploading index file: \(error.localisedDescription())")
            relay(recordingManager, newState: .error)
            supabase.cleanup(uuid: videoUUID)
        }
    }
}
