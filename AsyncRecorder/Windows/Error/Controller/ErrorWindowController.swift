//
//  ErrorWindowController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 16/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class ErrorWindowController: NSWindowController, NSWindowDelegate {
    
    let targetWidth = 300
    let targetHeight = 100
    
    init() {
        let window = NSWindow()
        window.backingType = .buffered
        window.styleMask = [.closable]
        
        super.init(window: window)
        window.delegate = self
        
        window.contentView = NSHostingView(rootView: ErrorView())

        // general config
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.collectionBehavior = .canJoinAllSpaces
        
        // set frame origin (slide in from bottom right corner)
        guard let screen = window.screen else {
            return
        }
        window.setFrame(NSRect(x: Int(screen.visibleFrame.maxX), y: Int(screen.visibleFrame.maxY) - targetHeight - 10, width: targetWidth, height: targetHeight), display: true, animate: false)
        window.animator().setFrame(NSRect(x: Int(screen.visibleFrame.maxX) - targetWidth - 10, y: Int(screen.visibleFrame.maxY) - targetHeight - 10, width: targetWidth, height: targetHeight), display: true, animate: true)
    }
    
    override func showWindow(_ sender: Any?) {
        DispatchQueue.main.async {
            super.showWindow(sender)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
            self.close()
        }
    }
    
    override func close() {
        guard let window = self.window, let screen = window.screen else {
            super.close()
            return
        }
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                window.animator().setFrame(NSRect(x: Int(screen.visibleFrame.maxX), y: Int(screen.visibleFrame.maxY) - self.targetHeight - 10, width: self.targetWidth, height: self.targetHeight), display: true, animate: true)
            }, completionHandler: {
                super.close()
            })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            self.window?.contentView = nil
        }
    }
}
