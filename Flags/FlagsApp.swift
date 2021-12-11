//
//  FlagsApp.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

@main
struct FlagsApp: App {
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
    var authWindowController: AuthWindowController?
    
    var micManager: MicManager?
    var camManager: CamManager?
    var recordingManager: RecordingManager?
    var authManager: AuthManager?

    override class func awakeFromNib() {}
        
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application launching")
        
        NSApplication.shared.delegate = self
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button, let itemImage = NSImage(named:NSImage.Name("StatusBarButtonImage")), itemImage.isTemplate {
            button.image = itemImage
            button.action = #selector(togglePopover)
        }
        
        micManager = MicManager()
        camManager = CamManager(self)
        authManager = AuthManager(self)
        recordingManager = RecordingManager(micManager: micManager!, delegate: self)
        
        if authManager?.state == .unauthenticated {
            showAuthWindow()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDevices), name: NSNotification.Name.AVCaptureDeviceWasConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDevices), name: NSNotification.Name.AVCaptureDeviceWasDisconnected, object: nil)
    }
    
    @objc func togglePopover() {
        if popoverController != nil && popoverController!.isShown {
            closePopover()
        } else if authManager?.state == .authenticated {
            showPopover()
        }
    }
    
    @objc func refreshDevices() {
        micManager?.getDevices()
        camManager?.getDevices()
    }

    func showPopover() {
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
            authManager?.refreshToken()
        }
    }

    func closePopover() {
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
        print("showing preview")
        camWindowController = CameraWindowController(camManager: camManager)
        camWindowController!.showWindow(nil)
    }
    
    func closeCameraPreview(){
        camWindowController?.close()
        camManager?.stopRunning()
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
    
    func closeCountdownWindow() {
        countdownWindowController?.close()
    }
    
    func showPreviewWindow(url: String, videoID: String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
            let previewWindowController = PreviewWindowController(url: url, videoID: videoID)
            previewWindowController.showWindow(nil)
        }
    }
    
    func showAuthWindow(){
        guard let authManager = authManager else {
            return
        }
        authWindowController = AuthWindowController(manager: authManager)
        authWindowController?.showWindow(self)
    }
    
    func closeAuthWindow(){
        authWindowController?.close()
    }
    
    func showErrorWindow(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){
            let errorWindowController = ErrorWindowController()
            errorWindowController.showWindow(self)
        }
    }
}
