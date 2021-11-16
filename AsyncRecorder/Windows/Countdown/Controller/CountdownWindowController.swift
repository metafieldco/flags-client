//
//  CountdownWindowController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class CountdownWindowController: NSWindowController, NSWindowDelegate{
    
    init(recordingManager: RecordingManager, width: CGFloat, height: CGFloat) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.closable, .resizable],
            backing: .buffered, defer: false)
        
        let countdownView = CountdownView().environmentObject(recordingManager)
        window.contentView = NSHostingView(rootView: countdownView)

        // general config
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.backgroundColor = .clear
        window.isMovable = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = .canJoinAllSpaces

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
}
