//
//  CamManager.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AppKit
import AVFoundation

class CamManager: ObservableObject {
    weak private var delegate: AppDelegate?
    private var captureSession: AVCaptureSession
    
    var previewLayer: AVCaptureVideoPreviewLayer
    
    init(_ delegate: AppDelegate){
        self.delegate = delegate
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }
    
    @Published var hovering = false
    
    @Published var size: CameraSize = .regular {
        didSet(old) {
            if old == size {
                return
            }
            delegate?.updateCameraSize(lastSize: old)
        }
    }
    
    @Published var device: CaptureDevice = noCamera {
        didSet {
            switch device {
            case .empty(_):
                delegate?.closeCameraPreview()
            case .device(_):
                if !self.isGranted{
                    checkAuthorization()
                    return
                }
                configureCaptureSession()
                if case .empty(_) = oldValue {
                    delegate?.showCameraPreview()
                }
            }
        }
    }
    
    @Published var devices: [CaptureDevice] = [noCamera] + AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified).devices.map{CaptureDevice.device($0)}
    
    @Published var isGranted = false {
        didSet{
            if !self.isGranted {
                if case .device(_) = device {
                    DispatchQueue.main.async {
                        self.device = noCamera
                    }
                }
            }
        }
    }
    
    func stopRunning(){
        captureSession.stopRunning()
    }
    
    func configureCaptureSession() {
        guard case let .device(newCameraDevice) = self.device else {
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
    
        // remove current camera if there is one
        if let currentCameraInput = captureSession.inputs.first {
            captureSession.removeInput(currentCameraInput)
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCameraDevice)
            
            guard captureSession.canAddInput(newInput) == true else {
                return
            }
            captureSession.addInput(newInput)
            
            captureSession.commitConfiguration()
            
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
            
            if let connection = self.previewLayer.connection, connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        catch {
            print("Something went wrong - ", error.localizedDescription)
        }
    }
    
    func getDevices(){
        let newDevices = [noCamera] + AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown], mediaType: .audio, position: .unspecified).devices.map{ CaptureDevice.device($0)}
        DispatchQueue.main.async {
            self.devices = newDevices
        }
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.isGranted = true
                configureCaptureSession()
                delegate?.showCameraPreview()

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.isGranted = granted
                        self?.delegate?.showPopover()
                    }
                }

            case .denied: // The user has previously denied access.
                self.isGranted = false
                return

            case .restricted: // The user can't grant access due to restrictions.
                self.isGranted = false
                return
        @unknown default:
            fatalError()
        }
    }
}
