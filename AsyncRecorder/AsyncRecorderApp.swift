//
//  AsyncRecorderApp.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

@main
struct AsyncRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    
    var popoverController: PopoverController?
    var countdownWindowController: CountdownWindowController?
    var camWindowController: CameraWindowController?
    
    var micManager: MicManager?
    var camManager: CamManager?
    var recordingManager: RecordingManager?

    override class func awakeFromNib() {}
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application launching")
        
        NSApplication.shared.delegate = self
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button, let itemImage = NSImage(named:NSImage.Name("StatusBarButtonImage")), itemImage.isTemplate {
            button.image = itemImage
            button.action = #selector(togglePopover(_:))
        }
        
        micManager = MicManager()
        camManager = CamManager(self)
        recordingManager = RecordingManager(micManager: micManager!, delegate: self)
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popoverController != nil && popoverController!.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: Any?) {
        if popoverController == nil {
            guard let micManager = micManager, let camManager = camManager, let recordingManager = recordingManager else {
                return
            }
            popoverController = PopoverController(appDelegate: self, micManager: micManager, camManager: camManager, recordingManager: recordingManager)
        }
        if recordingManager?.state == .recording{
            recordingManager?.stop()
        }else{
            guard let button = statusBarItem?.button else {
                return
            }
            popoverController?.show(button: button)
        }
    }

    func closePopover(_ sender: Any?) {
        popoverController?.close()
    }
    
    func refreshPopover(){
        guard let micManager = micManager else {
            return
        }
        recordingManager = RecordingManager(micManager: micManager, delegate: self)
        popoverController?.setup(recordingManager: recordingManager!)
    }
    
    func showCameraPreview(){
        guard let camManager = camManager else {
            return
        }
        camWindowController = CameraWindowController(camManager: camManager)
        camWindowController!.showWindow(nil)
    }
    
    func deleteCameraPreview(){
        camWindowController?.close()
    }
    
    func updateCameraSize(lastSize: CameraSize) {
        camWindowController?.resize(lastSize: lastSize)
    }
    
    func showCountdownWindow() {
        guard let screen = NSScreen.main, let recordingManager = recordingManager else {
            return
        }
        countdownWindowController = CountdownWindowController(recordingManager: recordingManager, width: screen.frame.width, height: screen.frame.height)
        countdownWindowController?.showWindow(nil)
    }
    
    func deleteCountdownWindow() {
        countdownWindowController?.close()
    }
    
    func showPreviewWindow(url: String, videoID: String){
        // Without the delay the animation doesn't work properly - might be because initilalising with the thumbnail is intensive (500kb)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
            let previewWindowController = PreviewWindowController(url: url, videoID: videoID)
            previewWindowController.showWindow(nil)
        }
    }
}
