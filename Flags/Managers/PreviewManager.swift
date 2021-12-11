//
//  PreviewManager.swift
//  Flags
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation

class PreviewManager: ObservableObject {
    
    enum PreviewButtonState {
        case copied
        case deleted
        case editing
        case none
    }
    
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
