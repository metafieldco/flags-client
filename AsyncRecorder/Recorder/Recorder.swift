//
//  Recorder.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import Foundation
import AVFoundation
import SwiftUI

class Recorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVAssetWriterDelegate {
    
    private var captureSession: AVCaptureSession?
    private var videoCaptureOutputDevice: AVCaptureVideoDataOutput?
    private var audioCaptureOutputDevice: AVCaptureAudioDataOutput?
    private var documentDirectory: URL?
    
    private let assetWriter: AVAssetWriter
    private let audioWriterInput: AVAssetWriterInput
    private let videoWriterInput: AVAssetWriterInput
    private var segmentIndex = 0
    
    override init() {
        // Create the aseet writer
        assetWriter = AVAssetWriter(contentType: UTType(outputContentType.rawValue)!)
        
        // Create the asset writer inputs
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        audioWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.expectsMediaDataInRealTime = true
        assetWriter.add(audioWriterInput)
        assetWriter.add(videoWriterInput)
        
        super.init()
        
        // Configure the asset writer for writing data in fragmented MPEG-4 format.
        assetWriter.outputFileTypeProfile = outputFileTypeProfile
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: Double(segmentDuration), preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = startTimeOffset
        assetWriter.delegate = self
        
        // Configure output directory
        guard let d = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else {
            return
        }
        self.documentDirectory = d
    }
    
    func record(to speech: Binding<String>) {
       relay(speech, message: "Requesting access")
       canAccess { authorized in
           guard authorized else {
               self.relay(speech, message: "Access denied")
               return
           }
           self.relay(speech, message: "Access granted")
           
           // Create the session
           self.relay(speech, message: "Booting video session")
           let session = AVCaptureSession()
           session.beginConfiguration()

           // Create input for screen capture
           let screenInput = AVCaptureScreenInput()
           if !session.canAddInput(screenInput) { return }
           session.addInput(screenInput)
           self.relay(speech, message: "Found input nodes")
           
           // Create input for microphone
           let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
           guard
               let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!),
               session.canAddInput(audioDeviceInput)
               else { return }
           session.addInput(audioDeviceInput)
           
           // Create video output device
           let videoOutput = AVCaptureVideoDataOutput()
           let videoDataOutputQueue = DispatchQueue(
                   label: "VideoDataOutputQueue"
               );
           videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
           guard session.canAddOutput(videoOutput) else { return }
           session.sessionPreset = .hd1920x1080
           session.addOutput(videoOutput)
           self.relay(speech, message: "Configured video output node")
           
           // Create video output device
           let audioOutput = AVCaptureAudioDataOutput()
           let audioDataOutputQueue = DispatchQueue(
                   label: "AudioDataOutputQueue"
               );
           audioOutput.setSampleBufferDelegate(self, queue: audioDataOutputQueue)
           guard session.canAddOutput(audioOutput) else { return }
           session.addOutput(audioOutput)
           self.relay(speech, message: "Configured audio output node")
           
           guard self.assetWriter.startWriting() else { return }
           self.assetWriter.startSession(atSourceTime: startTimeOffset)
           
           // Start running the session
           session.commitConfiguration()
           self.captureSession = session
           self.videoCaptureOutputDevice = videoOutput
           self.audioCaptureOutputDevice = audioOutput
           self.captureSession?.startRunning()
       }
    }
    
    func stop() {
        captureSession?.stopRunning()
        captureSession = nil
        videoCaptureOutputDevice = nil
        audioCaptureOutputDevice = nil
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
        
        print("writing segment")
        
        let segment = Segment(index: segmentIndex, data: segmentData, isInitializationSegment: isInitializationSegment, report: segmentReport)
        writeSegment(segment: segment)
        segmentIndex += 1
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        switch output {
        case audioCaptureOutputDevice:
            appendSample(writerInput: audioWriterInput, sampleBuffer: sampleBuffer)
        case videoCaptureOutputDevice:
            appendSample(writerInput: videoWriterInput, sampleBuffer: sampleBuffer)
        default:
            print("Skipping sample with unrecognized output type")
            return
        }
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
    
    private func appendSample(writerInput: AVAssetWriterInput, sampleBuffer: CMSampleBuffer) {
        do {
            if writerInput.isReadyForMoreMediaData {
                let offsetTimingSampleBuffer = try sampleBuffer.offsettingTiming(by: startTimeOffset)
                guard writerInput.append(offsetTimingSampleBuffer) else {
                    print("error in here mate")
                    throw assetWriter.error!
                }
            }
        }catch {
            print(error)
        }
    }
    
    private func canAccess(withHandler handler: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: // The user has previously granted access to the camera.
                handler(true)
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if granted {
                        handler(granted)
                    }
                }
            
            case .denied: // The user has previously denied access.
                handler(false)

            case .restricted: // The user can't grant access due to restrictions.
                handler(false)
            
            @unknown default:
                handler(false)
        }
    }
    
    private func relay(_ binding: Binding<String>, message: String) {
        DispatchQueue.main.async {
            binding.wrappedValue = message
        }
    }

}

extension CMSampleBuffer {
    func offsettingTiming(by offset: CMTime) throws -> CMSampleBuffer {
        let newSampleTimingInfos: [CMSampleTimingInfo]
        do {
            newSampleTimingInfos = try sampleTimingInfos().map {
                var newSampleTiming = $0
                newSampleTiming.presentationTimeStamp = $0.presentationTimeStamp + offset
                if $0.decodeTimeStamp.isValid {
                    newSampleTiming.decodeTimeStamp = $0.decodeTimeStamp + offset
                }
                return newSampleTiming
            }
        } catch {
            newSampleTimingInfos = []
        }
        let newSampleBuffer = try CMSampleBuffer(copying: self, withNewTiming: newSampleTimingInfos)
        try newSampleBuffer.setOutputPresentationTimeStamp(newSampleBuffer.outputPresentationTimeStamp + offset)
        return newSampleBuffer
    }
}
