//
//  MicManager.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AppKit
import AVFoundation

class MicManager: ObservableObject {
    @Published var enabled = false {
        didSet {
            if enabled && !isGranted {
                checkAuthorization()
                return
            }
        }
    }
    
    @Published var isGranted = false {
        didSet{
            if !self.isGranted && self.enabled{
                DispatchQueue.main.async {
                    self.enabled = false
                }
            }
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

