//
//  Recorder.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import Foundation
import AVFoundation
import SwiftUI

class Recorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    private var captureSession: AVCaptureSession?
    private var outputDevice: AVCaptureMovieFileOutput?
    
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
           
           // Create output device
           let videoOutput = AVCaptureMovieFileOutput()
           guard session.canAddOutput(videoOutput) else { return }
           session.sessionPreset = .photo
           session.addOutput(videoOutput)
           self.relay(speech, message: "Configured output node")
           
           // Start running the session
           session.commitConfiguration()
           self.captureSession = session
           self.outputDevice = videoOutput
           do {
               try self.startRecording()
           }catch{
               print(error)
           }

       }
    }
    
    func stop() {
        captureSession?.stopRunning()
        outputDevice?.stopRecording()
        captureSession = nil
        outputDevice = nil
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print(error!)
            return
        }
    }
    
    private func startRecording() throws {
        self.captureSession?.startRunning()
        guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else { return }
        let url = documentDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        self.outputDevice?.startRecording(to: url, recordingDelegate: self)
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
