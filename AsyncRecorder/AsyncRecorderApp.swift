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
    var popover = NSPopover()
    var statusBarItem: NSStatusItem!
    var camWindow: NSWindow?
    var micManager: MicManager?
    var camManager: CamManager?
    var recording: RecordingStatus?
    var capture: Capture?

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
        recording = RecordingStatus(self)
        capture = Capture(recordingStatus: recording!, micManager: micManager!)
        
        let popupVc = NSViewController()
        let popupView = PopupView(capture: capture)
        popupVc.view = NSHostingView(rootView: popupView.environmentObject(micManager!).environmentObject(camManager!).environmentObject(recording!))
        
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
        if recording?.state == .recording{
            capture?.stop()
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
    
    func showCameraPreview(){
        let camView = CameraPreviewView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 150),
            styleMask: [.closable, .resizable],
            backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: camView)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Async Recorder Facecam")
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = true
        window.isMovableByWindowBackground = true
        
        camWindow = window
    
    }
    
    func deleteCameraPreview(){
        print("deleting")
        camWindow?.contentView = nil
        camWindow?.close()
    }
    
    func popoverDidShow(_ notification: Notification) {
        print("Popup open delegate function triggered")
        guard let cm = camManager else{
            return
        }
        guard let state = recording?.state else {
            return
        }
        switch state {
        case .finished(_), .error:
            return
        default:
            if cm.enabled && cm.isGranted {
                showCameraPreview()
            }
        }
    }
    
    func popoverDidClose(_ notification: Notification) {
        print("Popup close delegate function triggered")
        if recording?.state != .recording {
            deleteCameraPreview()
        }
    }
    
    func refreshPopup(){
        capture = Capture(recordingStatus: recording!, micManager: micManager!)
        
        let popupVc = NSViewController()
        let popupView = PopupView(capture: capture)
        popupVc.view = NSHostingView(rootView: popupView.environmentObject(micManager!).environmentObject(camManager!).environmentObject(recording!))
        
        popover.contentViewController = popupVc
    }

}
