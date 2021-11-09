//
//  PreviewWindowController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class PreviewManager: ObservableObject {
    @Published var isHovering = true
}

class PreviewWindowController: NSWindowController, NSWindowDelegate {
    
    let previewManager = PreviewManager()
    let targetWidth = 288
    let targetHeight = 180
    
    init() {
        let window = NSWindow()
        window.backingType = .buffered
        window.styleMask = [.closable]
        
        super.init(window: window)
        window.delegate = self
        
        let previewView = PreviewView().environmentObject(previewManager)
        window.contentView = NSHostingView(rootView: previewView)

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
        window.setFrame(NSRect(x: Int(screen.visibleFrame.maxX), y: Int(screen.visibleFrame.minY) + 10, width: targetWidth, height: targetHeight), display: true, animate: false)
        window.animator().setFrame(NSRect(x: Int(screen.visibleFrame.maxX) - targetWidth - 10, y: Int(screen.visibleFrame.minY) + 10, width: targetWidth, height: targetHeight), display: true, animate: true)
        
        // set tracking area for hovering
        guard let view = window.contentView else {
            return
        }
        let trackingArea = NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
            withAnimation{
                self.previewManager.isHovering = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0){
            guard let window = self.window, let screen = window.screen else {
                return
            }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                window.animator().setFrame(NSRect(x: Int(screen.visibleFrame.maxX), y: Int(screen.visibleFrame.minY) + 10, width: self.targetWidth, height: self.targetHeight), display: true, animate: true)
            }, completionHandler: {
                self.close()
            })
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        withAnimation{
            self.previewManager.isHovering = true
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        withAnimation{
            self.previewManager.isHovering = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    func windowWillClose(_ notification: Notification) {
        self.window?.contentView = nil
    }
}
