//
//  Write.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 26/10/2021.
//

import Foundation
import AVFoundation
import Combine
import AppKit
import SwiftUI

class Writer: NSObject, AVAssetWriterDelegate {
    
    let assetWriter: AVAssetWriter
    let audioWriterInput: AVAssetWriterInput
    let videoWriterInput: AVAssetWriterInput

    private var webAppVideoUrl: String?
    
    private let supabase: Supabase
    private let recordingStatus: Binding<RecordingStatus>
    
    private lazy var playlistState = IndexFileState()
    private lazy var segmentIndex = 0
    private lazy var folderUUID = UUID()
    
    init(recordingStatus: Binding<RecordingStatus>) {
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
        
        self.recordingStatus = recordingStatus
        
        super.init()
    }
    
    func setup() throws {
        guard let tmp = Bundle.main.object(forInfoDictionaryKey: "WEB_APP_VIDEO_URL") as? String, !tmp.isEmpty else {
            throw RuntimeError("WEB_APP_VIDEO_URL not found in the environment.")
        }
        webAppVideoUrl = tmp
        
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
        assetWriter.finishWriting {
            if cleanup {
                // there was an error, cleanup any segments we have streamed to s3
                self.supabase.deleteFolder(uuid: self.folderUUID)
                return
            }
            if self.assetWriter.status == .completed {
                // upload the playlist file + show video in browser
                let finalPlaylist = generateFullPlaylist(state: self.playlistState)
                guard let data = finalPlaylist.data(using: .utf8) else {
                    print("Failed to generate full playlist file. Cleaning up.")
                    relay(self.recordingStatus, newStatus: .Error)
                    self.supabase.deleteFolder(uuid: self.folderUUID)
                    return
                }
                do {
                    try self.supabase.uploadFile(uuid: self.folderUUID, filename: indexFileName, data: data, finish: self.redirectOnIndexFileUpload)
                }catch {
                    print("Error when uploading playlist file: \(error.localizedDescription). Cleaning up.")
                    relay(self.recordingStatus, newStatus: .Error)
                    self.supabase.deleteFolder(uuid: self.folderUUID)
                }
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
        
        do {
            try self.supabase.uploadFile(uuid: folderUUID, filename: segmentFileName, data: segment.data) { error in
                if error != nil {
                    print("Error when uploading segment: \(error!.localizedDescription). Cleaning up.")
                    self.stop(true)
                    relay(self.recordingStatus, newStatus: .Error)
                    // TODO: check how this affects capture output delegate
                }
                print("Uploaded segment \(segmentFileName) to s3")
            }
        }catch{
            print("Error when uploading segment: \(error.localizedDescription). Cleaning up.")
            self.stop(true)
            relay(self.recordingStatus, newStatus: .Error)
            // TODO: check how this affects capture output delegate
        }
        
        playlistState = updatePlaylistForSegment(state: playlistState, segment: segment)
        
        segmentIndex += 1
    }
    
    private func redirectOnIndexFileUpload(error: RuntimeError?){
        if error != nil {
            print("Error when uploading index file: \(error!.localizedDescription)")
            relay(recordingStatus, newStatus: .Error)
            supabase.deleteFolder(uuid: folderUUID) // don't need to call stop as we already will have done.
        }
        print("Uploaded playlist file to s3")
        if (webAppVideoUrl != nil), let url = URL(string: webAppVideoUrl!) {
            NSWorkspace.shared.open(url.appendingPathComponent(folderUUID.uuidString))
        }
    }
}
