//
//  PopoverController.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class PopoverController: NSObject, NSPopoverDelegate {
    
    let popover = NSPopover()
    
    var appDelegate: AppDelegate
    var micManager: MicManager
    var camManager: CamManager
    var recordingManager: RecordingManager?
    
    var isShown: Bool {
        return popover.isShown
    }
    
    init(appDelegate: AppDelegate, micManager: MicManager, camManager: CamManager, recordingManager: RecordingManager) {
        self.appDelegate = appDelegate
        self.micManager = micManager
        self.camManager = camManager
        
        super.init()
        
        popover.animates = false
        popover.behavior = .transient
        popover.delegate = self
        
        self.setup(recordingManager: recordingManager)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(recordingManager: RecordingManager){
        self.recordingManager = recordingManager
        
        let popupVc = NSViewController()
        let popupView = PopupView()
        popupVc.view = NSHostingView(rootView: popupView.environmentObject(micManager).environmentObject(camManager).environmentObject(recordingManager))
        
        popover.contentViewController = popupVc
    }
    
    func show(button: NSStatusBarButton){
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    
    func close(){
        popover.close()
    }
    
    func popoverDidShow(_ notification: Notification) {
        print("Popup open delegate function triggered")
        guard let state = recordingManager?.state else {
            return
        }
        switch state {
        case .finished(_, _), .error:
            return
        default:
            if camManager.enabled && camManager.isGranted {
                appDelegate.showCameraPreview()
            }
        }
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        guard let state = recordingManager?.state, state == .stopped, camManager.hovering else {
            return true
        }
        return false
    }
    
    func popoverDidClose(_ notification: Notification) {
        print("Popup close delegate function triggered")
        if recordingManager?.state != .recording {
            print("Deleting camera view")
            appDelegate.deleteCameraPreview()
        }
    }
}
