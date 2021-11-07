//
//  RecordingManager.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 07/11/2021.
//

import Foundation

enum RecordingState: Equatable {
    case stopped // default
    case recording
    case finished(String, String)
    case error
}

class RecordingManager: ObservableObject {
    
    @Published var countdown = 3
    
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
    
    var delegate: AppDelegate
    var capture: Capture!
    var timer: Timer?
    
    init(micManager: MicManager, delegate: AppDelegate){
        self.delegate = delegate
        self.capture = Capture(recordingManager: self, micManager: micManager)
    }
    
    func start() {
        state = .recording
        delegate.showCountdownWindow()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            if self.countdown > 1 {
                self.countdown -= 1
                print(self.countdown)
            }else {
                self.timer!.invalidate()
                self.delegate.deleteCountdownWindow()
                self.startRecording()
            }
        }
    }
    
    func stop(){
        capture.stop()
    }
    
    private func startRecording(){
        do {
            try capture.start()
        }catch{
            print(error)
            state = .error
        }
    }
}

// Updating a SwiftUI state variable from swift
func relay(_ object: RecordingManager, newState: RecordingState) {
    DispatchQueue.main.async {
        object.state = newState
    }
}