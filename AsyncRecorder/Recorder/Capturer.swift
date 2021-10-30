//
//  Capture.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 26/10/2021.
//

import Foundation
import AVFoundation

class Capturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession
    private var videoCaptureOutputDevice: AVCaptureVideoDataOutput
    private var audioCaptureOutputDevice: AVCaptureAudioDataOutput
    private var offsetTime: CMTime
    private var writer: Writer
    
    override init() {
        self.captureSession = AVCaptureSession()
        self.videoCaptureOutputDevice = AVCaptureVideoDataOutput()
        self.audioCaptureOutputDevice = AVCaptureAudioDataOutput()
        self.offsetTime = startTimeOffset
        self.writer = Writer()
        
        super.init()
    }
    
    func start(){
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = sessionPreset
        
        // Video input - screen
        let screenInput = AVCaptureScreenInput()
        if !self.captureSession.canAddInput(screenInput) { return }
        self.captureSession.addInput(screenInput)
        
        // Audio input - internal mic
        let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
        guard
            let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!),
            self.captureSession.canAddInput(audioDeviceInput)
            else { return }
        self.captureSession.addInput(audioDeviceInput)
        
        self.videoCaptureOutputDevice.alwaysDiscardsLateVideoFrames = true
        self.videoCaptureOutputDevice.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : kCVPixelFormatType_32BGRA]
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue");
        self.videoCaptureOutputDevice.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        guard self.captureSession.canAddOutput(self.videoCaptureOutputDevice) else { return }
        self.captureSession.addOutput(self.videoCaptureOutputDevice)
        
        let audioDataOutputQueue = DispatchQueue(label: "AudioDataOutputQueue");
        self.audioCaptureOutputDevice.setSampleBufferDelegate(self, queue: audioDataOutputQueue)
        guard self.captureSession.canAddOutput(self.audioCaptureOutputDevice) else { return }
        self.captureSession.addOutput(self.audioCaptureOutputDevice)
        
        self.captureSession.commitConfiguration()

        self.captureSession.startRunning()
    }
    
    func stop(){
        writer.stop()
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let isVideo = output is AVCaptureVideoDataOutput
        
        if CMSampleBufferDataIsReady(sampleBuffer){
            
            // Immediately after the start, only audio data comes, so start writing after the first video comes.
            if isVideo && writer.assetWriter.status == .unknown {
                offsetTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                print("seconds mate:\(offsetTime.seconds)")
                if offsetTime == .zero {
                    return
                }
                writer.assetWriter.startWriting()
                writer.assetWriter.startSession(atSourceTime: startTimeOffset)
            }
            
            if writer.assetWriter.status == .failed {
                print(writer.assetWriter.error!)
                stop()
                
            }else if writer.assetWriter.status == .writing {
                
                // Presentation timestamp adjustment (minus offSetTime)
                print("original: \(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds), isVideo: \(isVideo)")
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
                    if isVideo, writer.videoWriterInput.isReadyForMoreMediaData {
                        writer.videoWriterInput.append(copyBuffer)
                    }else if !isVideo, writer.audioWriterInput.isReadyForMoreMediaData {
                        writer.audioWriterInput.append(copyBuffer)
                    }
                }else{
                    print("copy buffer not valid")
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Dropped some output! Whatever that means ...")
    }
    
    private func canAccess(withHandler handler: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: // The user has previously granted access to audo.
                handler(true)
            
            case .notDetermined: // The user has not yet been asked for audio access.
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
}
