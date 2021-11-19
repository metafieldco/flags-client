//
//  ControlMenu.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 17/11/2021.
//

import Foundation
import AppKit

class ControlMenu: NSMenu {
    init(){
        super.init(title: "Control menu")
        
        let recordItem = createItem("Record screen", "r")
        let quitItem = createItem("Quit", "q")
        
        items = [recordItem, .separator(), quitItem]
    }
    
    private func createItem(_ title: String, _ keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(test), keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }
    
    @objc private func test(){
        print("triggered")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
