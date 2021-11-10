//
//  PreviewWindowController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import Foundation
import AppKit
import SwiftUI

enum PreviewButtonState {
    case copied
    case deleted
    case editing
    case none
}

class PreviewManager: ObservableObject {
    
    weak var controller: PreviewWindowController?
    
    init(controller: PreviewWindowController) {
        self.controller = controller
    }
    
    @Published var isHovering = false
    @Published var state: PreviewButtonState = .none {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                self.controller?.close()
            }
        }
    }
}

class PreviewWindowController: NSWindowController, NSWindowDelegate {
    
    var previewManager: PreviewManager?
    let targetWidth = 288
    let targetHeight = 180
    
    init(url: String, videoID: String) {
        let window = NSWindow()
        window.backingType = .buffered
        window.styleMask = [.closable]
        
        super.init(window: window)
        window.delegate = self
        
        previewManager = PreviewManager(controller: self)
        let previewView = PreviewView(url: url, videoID: videoID).environmentObject(previewManager!)
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
        DispatchQueue.main.async {
            super.showWindow(sender)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0){
            guard let previewManager = self.previewManager, previewManager.state != .none else {
                self.close()
                return
            }
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
                window.animator().setFrame(NSRect(x: Int(screen.visibleFrame.maxX), y: Int(screen.visibleFrame.minY) + 10, width: self.targetWidth, height: self.targetHeight), display: true, animate: true)
            }, completionHandler: {
                super.close()
            })
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        DispatchQueue.main.async {
            withAnimation{
                self.previewManager?.isHovering = true
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        DispatchQueue.main.async {
            withAnimation{
                self.previewManager?.isHovering = false
            }
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
