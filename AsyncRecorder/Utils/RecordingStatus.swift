//
//  RecordingStatus.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AppKit
import SwiftUI

enum RecordingState: Equatable {
    case stopped // default
    case recording
    case finished(String, [String], String)
    case error
}

class RecordingStatus: ObservableObject {
    private var delegate: AppDelegate
    
    init(_ delegate: AppDelegate){
        self.delegate = delegate
    }
    
    @Published var state: RecordingState = .stopped {
        didSet(oldVal) {
            if oldVal == state {
                return // if it hasn't updated we are not interested
            }
            switch state {
            case .recording:
                print("Recording status changed to recording. Close popup")
                DispatchQueue.main.async {
                    self.delegate.closePopover(self)
                }
            case .error:
                print("Recording status changed to error. Removing camera view and showing popup.")
                DispatchQueue.main.async {
                    self.delegate.deleteCameraPreview()
                    self.delegate.showPopover(self)
                }
            case .stopped:
                print("Recording status changed to stopped. Closing and refreshing popup view so we can go again. Removing camera.")
                DispatchQueue.main.async {
                    self.delegate.closePopover(self)
                    self.delegate.refreshPopup()
                }
            case .finished:
                print("Recording status changed to finished. Closing camera view and showing popup for copying URL.")
                DispatchQueue.main.async {
                    self.delegate.deleteCameraPreview()
                    self.delegate.showPopover(self)
                }
                return
            }
        }
    }
}

// Updating a SwiftUI state variable from swift
func relay(_ object: RecordingStatus, newStatus: RecordingState) {
    DispatchQueue.main.async {
        object.state = newStatus
    }
}
