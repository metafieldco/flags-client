//
//  Capture.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 26/10/2021.
//

import Foundation
import AVFoundation
import SwiftUI

class Capture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession
    private var videoCaptureOutputDevice: AVCaptureVideoDataOutput
    private var audioCaptureOutputDevice: AVCaptureAudioDataOutput
    private var offsetTime: CMTime
    private var upload: Upload
    private var recordingStatus: Binding<RecordingStatus> // Used for UI updating in delegate callbacks
    
    init(recordingStatus: Binding<RecordingStatus>) {
        self.captureSession = AVCaptureSession()
        self.videoCaptureOutputDevice = AVCaptureVideoDataOutput()
        self.audioCaptureOutputDevice = AVCaptureAudioDataOutput()
        self.offsetTime = startTimeOffset
        self.upload = Upload(recordingStatus: recordingStatus)
        self.recordingStatus = recordingStatus
        
        super.init()
    }
    
    func start() throws {
        
        do {
            try upload.setup()
        }catch {
            throw error
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        // Video input - screen
        let screenInput = AVCaptureScreenInput()
        if !captureSession.canAddInput(screenInput) { throw RuntimeError("Could not add screen capture input to capture session") }
        captureSession.addInput(screenInput)
        
        // Audio input - internal mic
        let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
        guard
            let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!),
            captureSession.canAddInput(audioDeviceInput) else {
                throw RuntimeError("Could not add audio input to capture session")
            }
        captureSession.addInput(audioDeviceInput)
        
        videoCaptureOutputDevice.alwaysDiscardsLateVideoFrames = true
        videoCaptureOutputDevice.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : kCVPixelFormatType_32BGRA]
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue");
        videoCaptureOutputDevice.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        guard captureSession.canAddOutput(self.videoCaptureOutputDevice) else {
            throw RuntimeError("Could not add video output to capture session")
        }
        captureSession.addOutput(self.videoCaptureOutputDevice)
        
        let audioDataOutputQueue = DispatchQueue(label: "AudioDataOutputQueue");
        audioCaptureOutputDevice.setSampleBufferDelegate(self, queue: audioDataOutputQueue)
        guard captureSession.canAddOutput(self.audioCaptureOutputDevice) else {
            throw RuntimeError("Could not add audio output to capture session")
        }
        captureSession.addOutput(self.audioCaptureOutputDevice)
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    func stop(_ cleanup: Bool = false){
        upload.stop(cleanup)
        captureSession.stopRunning()
        relay(recordingStatus, newStatus: .Stopped)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let isVideo = output is AVCaptureVideoDataOutput
        
        if CMSampleBufferDataIsReady(sampleBuffer){
            
            // Immediately after the start, only audio data comes, so start writing after the first video comes.
            if isVideo && upload.assetWriter.status == .unknown {
                offsetTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if offsetTime == .zero {
                    return // TODO: narrow down why the first sample buffer comes so quickly
                }
                upload.assetWriter.startWriting()
                upload.assetWriter.startSession(atSourceTime: startTimeOffset)
            }
            
            // Catch writer issues - could be an issue with appending to writer inputs
            if upload.assetWriter.status == .failed {
                print(upload.assetWriter.error!)
                relay(recordingStatus, newStatus: .Error)
                stop(true)
                
            }else if upload.assetWriter.status == .writing {
                
                // Presentation timestamp adjustment (minus offSetTime)
                var copyBuffer: CMSampleBuffer?
                var count: CMItemCount = 1
                var info = CMSampleTimingInfo()
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
                info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, offsetTime)
                CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                                      sampleBuffer: sampleBuffer,
                                                      sampleTimingEntryCount: 1,
                                                      sampleTimingArray: &info,
                                                      sampleBufferOut: &copyBuffer)
                if let copyBuffer = copyBuffer, copyBuffer.isValid {
                    if isVideo, upload.videoWriterInput.isReadyForMoreMediaData {
                        upload.videoWriterInput.append(copyBuffer)
                    }else if !isVideo, upload.audioWriterInput.isReadyForMoreMediaData {
                        upload.audioWriterInput.append(copyBuffer)
                    }
                }else{
                    print("Copied sample buffer is not valid")
                    relay(recordingStatus, newStatus: .Error)
                    stop(true)
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capturer dropped sample buffer: \(String(describing: sampleBuffer.formatDescription))")
        relay(recordingStatus, newStatus: .Error)
        stop(true)
    }
}
