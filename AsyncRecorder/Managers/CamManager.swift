//
//  CamManager.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AppKit
import AVFoundation

class CamManager: ObservableObject {
    weak private var delegate: AppDelegate?
    
    init(_ delegate: AppDelegate){
        self.delegate = delegate
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
    
    @Published var enabled = false {
        didSet {
            if self.enabled && !self.isGranted {
                self.checkAuthorization()
                return
            }
            
            if self.enabled {
                self.delegate?.showCameraPreview()
            }else {
                self.delegate?.deleteCameraPreview()
            }
        }
    }
    
    @Published var isGranted = false {
        didSet{
            if self.isGranted {
                self.delegate?.showCameraPreview()
            }else if self.enabled{
                self.enabled = false
            }
        }
    }
    
    @Published var devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified).devices
    
    func getDevices(){
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
        DispatchQueue.main.async {
            self.devices = discoverySession.devices
        }
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.isGranted = true

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.isGranted = granted
                        }
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
