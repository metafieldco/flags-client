//
//  MicManager.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AppKit
import AVFoundation
import UserNotifications

class MicManager: ObservableObject {
    
    @Published var device: CaptureDevice = noMicrophone {
        didSet {
            if case .device(_) = device{
                if !isGranted {
                    checkAuthorization()
                }
            }
        }
    }
    
    @Published var devices = [noMicrophone] + AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown], mediaType: .audio, position: .unspecified).devices.map{ CaptureDevice.device($0) }
    
    @Published var isGranted = false {
        didSet{
            if !self.isGranted{
                if case .device(_) = device {
                    DispatchQueue.main.async {
                        self.device = noMicrophone
                    }
                }
            }
        }
    }
    
    func getDevices(){
        let newDevices = [noMicrophone] + AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown], mediaType: .audio, position: .unspecified).devices.map{ CaptureDevice.device($0)}
        DispatchQueue.main.async {
            self.devices = newDevices
        }
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: // The user has previously granted access to the camera.
                self.isGranted = true

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
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

