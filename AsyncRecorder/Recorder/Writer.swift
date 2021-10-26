//
//  Write.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 26/10/2021.
//

import Foundation
import AVFoundation

class Writer: NSObject, AVAssetWriterDelegate {
    
    let assetWriter: AVAssetWriter
    let audioWriterInput: AVAssetWriterInput
    let videoWriterInput: AVAssetWriterInput
    private var segmentIndex = 0
    private var documentDirectory: URL
    
    override init() {
        // Create the asset writer
        self.assetWriter = AVAssetWriter(contentType: UTType(outputContentType.rawValue)!)
        
        // Create the asset writer inputs
        self.audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
        self.videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        audioWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.expectsMediaDataInRealTime = true
        assetWriter.add(audioWriterInput)
        assetWriter.add(videoWriterInput)
        
        // Calculate directory
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else { fatalError() }
        self.documentDirectory = directory
        
        super.init()
        
        // Configure the asset writer for writing data in fragmented MPEG-4 format.
        assetWriter.outputFileTypeProfile = outputFileTypeProfile
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: Double(segmentDuration), preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = startTimeOffset
        assetWriter.delegate = self
    }
    
    func start(){
        guard assetWriter.startWriting() else { return }
        assetWriter.startSession(atSourceTime: startTimeOffset)
    }
    
    func stop(){
        audioWriterInput.markAsFinished()
        videoWriterInput.markAsFinished()
        assetWriter.finishWriting {
            if self.assetWriter.status == .completed {
                print("wahoo")
            }else {
                assert(self.assetWriter.status == .failed)
                print(self.assetWriter.error!)
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
        writeSegment(segment: segment)
        segmentIndex += 1
    }
    
    private func writeSegment(segment: Segment){
        let segmentFileName = segment.fileName(forPrefix: segmentFileNamePrefix)
        let segmentFileURL = URL(fileURLWithPath: segmentFileName, isDirectory: false, relativeTo: documentDirectory)

        print("writing \(segment.data.count) bytes to \(segmentFileName)")
        do {
            try segment.data.write(to: segmentFileURL)
        }catch {
            print(error)
        }
    }
}

// This is a simple structure that combines the output of AVAssetWriterDelegate with an increasing segment index.
struct Segment {
    let index: Int
    let data: Data
    let isInitializationSegment: Bool
    let report: AVAssetSegmentReport?
}

extension Segment {
    func fileName(forPrefix prefix: String) -> String {
        let fileExtension: String
        if isInitializationSegment {
            fileExtension = "mp4"
        } else {
            fileExtension = "m4s"
        }
        return "\(prefix)\(index).\(fileExtension)"
    }
}
