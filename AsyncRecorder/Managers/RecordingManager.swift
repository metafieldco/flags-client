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
                self.delegate?.closePopover(self)
                self.delegate?.showCountdownWindow()
                toggleDesktop(hide: true)
            case .error:
                self.delegate?.deleteCameraPreview()
                self.delegate?.showErrorWindow()
                toggleDesktop(hide: false)
                self.delegate?.refreshPopover()
            case let .finished(url, videoID):
                self.delegate?.showPreviewWindow(url: url, videoID: videoID)
                self.delegate?.deleteCameraPreview()
                toggleDesktop(hide: false)
                self.delegate?.refreshPopover()
            default:
                return
            }
        }
    }
    
    weak private var delegate: AppDelegate?
    private var capture: Capture!
    private var timer: Timer?
    private var isSetupError = false
    
    init(micManager: MicManager, delegate: AppDelegate){
        self.delegate = delegate
        self.capture = Capture(recordingManager: self, micManager: micManager)
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.capture.setup()
            }catch{
                self.isSetupError = true
                print(error)
                
                DispatchQueue.main.async {
                    self.state = .error
                }
            }
        }
        
        DispatchQueue.main.async {
            self.state = .recording
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ [weak self] _ in
            guard let self = self, !self.isSetupError else { return }
            if self.countdown > 1 {
                self.countdown -= 1
            }else {
                self.timer!.invalidate()
                
                self.delegate?.deleteCountdownWindow()
                
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
func relay(_ object: RecordingManager?, newState: RecordingState) {
    guard let object = object else {
        return
    }
    DispatchQueue.main.async {
        object.state = newState
    }
}
