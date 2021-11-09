//
//  PreviewWindowController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class PreviewWindowController: NSWindowController, NSWindowDelegate {
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 432, height: 270),
            styleMask: [.closable],
            backing: .buffered, defer: false)
        
        super.init(window: window)
        window.delegate = self
        
        let previewView = PreviewView(action: {
            self.close()
        })
        window.contentView = NSHostingView(rootView: previewView)

        // general config
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = .canJoinAllSpaces
        
        // set frame origin (bottom right corner)
        guard let screen = window.screen else {
            return
        }
        window.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - window.frame.width - 10, y: screen.visibleFrame.minY + 50))

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window?.contentView = nil
    }
}
