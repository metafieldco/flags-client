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
    private let writer: Writer
    
    init(writer: Writer) {
        self.writer = writer
        self.captureSession = AVCaptureSession()
        self.videoCaptureOutputDevice = AVCaptureVideoDataOutput()
        self.audioCaptureOutputDevice = AVCaptureAudioDataOutput()
        
        super.init()
    }
    
    func start(){
        canAccess { authorized in
            guard authorized else {
                print("access denied")
                return
            }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1920x1080
            
            let screenInput = AVCaptureScreenInput()
            if !self.captureSession.canAddInput(screenInput) { return }
            self.captureSession.addInput(screenInput)
            
            let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified)
            guard
                let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!),
                self.captureSession.canAddInput(audioDeviceInput)
                else { return }
            self.captureSession.addInput(audioDeviceInput)
            
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
    }
    
    func stop(){
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        switch output {
        case audioCaptureOutputDevice:
            appendSample(writerInput: writer.audioWriterInput, sampleBuffer: sampleBuffer)
        case videoCaptureOutputDevice:
            appendSample(writerInput: writer.videoWriterInput, sampleBuffer: sampleBuffer)
        default:
            print("Skipping sample with unrecognized output type")
            return
        }
    }
    
    private func appendSample(writerInput: AVAssetWriterInput, sampleBuffer: CMSampleBuffer) {
        do {
            if writerInput.isReadyForMoreMediaData {
                let offsetTimingSampleBuffer = try sampleBuffer.offsettingTiming(by: startTimeOffset)
                guard writerInput.append(offsetTimingSampleBuffer) else {
                    throw writer.assetWriter.error!
                }
            }
        }catch {
            print(error)
        }
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

