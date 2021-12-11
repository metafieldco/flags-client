//
//  AuthWindowController.swift
//  Flags
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class AuthWindowController: NSWindowController, NSWindowDelegate {
    
    init(manager: AuthManager) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 500), styleMask: [.closable, .resizable, .miniaturizable, .titled], backing: .buffered, defer: false)
        
        super.init(window: window)
        window.delegate = self
    
        window.contentView = NSHostingView(rootView: AuthView().environmentObject(manager))

        // general config
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(self)
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.center()
        
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
