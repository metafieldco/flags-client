//
//  CameraWindowController.swift
//  Flags
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class CameraWindowController: NSWindowController, NSWindowDelegate{
    
    var camManager: CamManager
    var lastOrigin: NSPoint?
    
    init(camManager: CamManager) {
        self.camManager = camManager
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: camManager.size.width, height: camManager.size.height),
            styleMask: [.closable, .resizable],
            backing: .buffered, defer: false)
        
        let camView = CameraPreviewView().environmentObject(camManager)
        window.contentView = NSHostingView(rootView: camView)

        // general config
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = .canJoinAllSpaces
        
        if camManager.size != .fullScreen {
            // set frame origin (bottom left corner)
            guard let screen = window.screen else {
                super.init(window: window)
                window.delegate = self
                return
            }
            window.setFrameOrigin(NSPoint(x: 0, y: screen.visibleFrame.minY + 50))
        }

        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            self.window?.contentView = nil
        }
    }
    
    func resize(lastSize: CameraSize){
        guard let window = self.window else {
            return
        }
        let size = camManager.size
        switch size {
        case .regular, .large:
            var frame = window.frame
            frame.size = NSSize(width: size.width, height: size.height)
            
            if lastSize == .fullScreen {
                DispatchQueue.main.async {
                    window.setFrame(frame, display: true)
                    if let lastOrigin = self.lastOrigin {
                        window.setFrameOrigin(lastOrigin)
                    }
                }
            }else{
                DispatchQueue.main.async {
                    window.setFrame(frame, display: true, animate: true)
                }
            }
        case .fullScreen:
            lastOrigin = window.frame.origin // save current origin to go back to
            
            guard let screen = window.screen ?? NSScreen.main else {
                return
            }
            DispatchQueue.main.async {
                window.setFrame(screen.frame, display: true)
            }
        }
        
        // Delete cam size in user defaults
        NSWindow.removeFrame(usingName: window.frameAutosaveName)
    }
}
