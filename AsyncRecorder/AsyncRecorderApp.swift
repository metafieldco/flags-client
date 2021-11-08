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

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusBarItem: NSStatusItem!
    
    var popover = NSPopover()
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
        
        let popupVc = NSViewController()
        let popupView = PopupView()
        popupVc.view = NSHostingView(rootView: popupView.environmentObject(micManager!).environmentObject(camManager!).environmentObject(recordingManager!))
        
        popover.contentViewController = popupVc
        popover.animates = false
        popover.behavior = .transient
        popover.delegate = self
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: Any?) {
        if recordingManager?.state == .recording{
            recordingManager?.stop()
        }else{
            if let button = statusBarItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
    
    func popoverDidShow(_ notification: Notification) {
        print("Popup open delegate function triggered")
        guard let cm = camManager else{
            return
        }
        guard let state = recordingManager?.state else {
            return
        }
        switch state {
        case .finished(_, _), .error:
            return
        default:
            if cm.enabled && cm.isGranted {
                showCameraPreview()
            }
        }
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        guard let hovering = camManager?.hovering, let state = recordingManager?.state, state == .stopped, hovering else {
            return true
        }
        return false
    }
    
    func popoverDidClose(_ notification: Notification) {
        print("Popup close delegate function triggered")
        if recordingManager?.state != .recording {
            deleteCameraPreview()
        }
    }
    
    func refreshPopup(){
        recordingManager = RecordingManager(micManager: micManager!, delegate: self)
        
        let popupVc = NSViewController()
        let popupView = PopupView()
        popupVc.view = NSHostingView(rootView: popupView.environmentObject(micManager!).environmentObject(camManager!).environmentObject(recordingManager!))
        
        popover.contentViewController = popupVc
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
}
