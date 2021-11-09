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
                // TODO: won't need this case once we change how error's are shown
                print("Recording status changed to stopped. We can go again.")
                DispatchQueue.main.async {
                    self.delegate.closePopover(self)
                    self.delegate.refreshPopover()
                }
            case let .finished(url, videoID):
                print("Recording status changed to finished. Closing camera view and showing preview view.")
                self.delegate.showPreviewWindow(url: url, videoID: videoID)
                DispatchQueue.main.async {
                    self.delegate.deleteCameraPreview()
                    toggleDesktop(hide: false)
                    self.delegate.refreshPopover()
                }
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
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.capture.setup()
            }catch{
                print(error)
                self.state = .error
            }
        }
        
        toggleDesktop(hide: true)
        
        state = .recording
        delegate.showCountdownWindow()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            if self.countdown > 1 {
                self.countdown -= 1
            }else {
                self.timer!.invalidate()
                self.delegate.deleteCountdownWindow()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.capture.start()
                }
            }
        }
    }
    
    func stop(){
        capture.stop()
    }

}

// Updating a SwiftUI state variable from swift
func relay(_ object: RecordingManager, newState: RecordingState) {
    DispatchQueue.main.async {
        object.state = newState
    }
}
