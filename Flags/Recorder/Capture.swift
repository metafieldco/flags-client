//
//  Capture.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AVFoundation
import SwiftUI

class Capture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    weak private var recordingManager: RecordingManager?
    private var micManager: MicManager
    
    private var captureSession: AVCaptureSession
    private var videoCaptureOutputDevice: AVCaptureVideoDataOutput
    private var audioCaptureOutputDevice: AVCaptureAudioDataOutput
    private var offsetTime: CMTime
    private var upload: Upload
    private var supabase: Supabase
    private var videoUUID = UUID().uuidString.lowercased()
    
    init(recordingManager: RecordingManager?, micManager: MicManager) {
        self.captureSession = AVCaptureSession()
        self.videoCaptureOutputDevice = AVCaptureVideoDataOutput()
        self.audioCaptureOutputDevice = AVCaptureAudioDataOutput()
        self.offsetTime = startTimeOffset
        self.supabase = Supabase()
        self.upload = Upload(recordingManager: recordingManager, supabase: supabase, videoUUID: videoUUID)
        self.recordingManager = recordingManager
        self.micManager = micManager
        
        super.init()
    }
    
    func setup() throws {
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
        if case let .device(device) = micManager.device {
            guard
                let audioDeviceInput = try? AVCaptureDeviceInput(device: device),
                captureSession.canAddInput(audioDeviceInput) else {
                    throw RuntimeError("Could not add audio input to capture session")
                }
            captureSession.addInput(audioDeviceInput)
        }
        
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
    }
    
    func start() {
        captureSession.startRunning()
        
        Screenshot().capture()
        
        // whilst we are starting the session, upload the initial video record on a lower priority background thread
        DispatchQueue.global(qos: .utility).async {
            do {
                try self.supabase.insertVideoRecord(uuid: self.videoUUID) { [weak self] result in
                    switch result {
                    case .success(_):
                        print("Successfully inserted video record.")
                    case .failure(let error):
                        self?.captureSession.stopRunning()
                        relay(self?.recordingManager, newState: .error)
                        print("Failed to insert video record for video: \(error.localizedDescription)")
                    }
                    return
                }
            }catch{
                self.captureSession.stopRunning()
                relay(self.recordingManager, newState: .error)
                print("Runtime error when inserting video record for video: \(error.localizedDescription)")
            }
        }
    }
    
    func stop(_ cleanup: Bool = false){
        upload.stop(cleanup)
        captureSession.stopRunning()
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
                relay(recordingManager, newState: .error)
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
                    relay(recordingManager, newState: .error)
                    stop(true)
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capturer dropped sample buffer: \(String(describing: sampleBuffer.formatDescription))")
        relay(recordingManager, newState: .error)
        stop(true)
    }
}
