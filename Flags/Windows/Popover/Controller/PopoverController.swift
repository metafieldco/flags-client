//
//  PopoverController.swift
//  Flags
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation
import AppKit
import SwiftUI

class PopoverController: NSObject, NSPopoverDelegate {
    
    private let popover = NSPopover()
    weak private var appDelegate: AppDelegate?
    private var micManager: MicManager
    private var camManager: CamManager
    private var recordingManager: RecordingManager?
    
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
        popupVc.view = NSHostingView(rootView: PopoverView().environmentObject(recordingManager).environmentObject(camManager).environmentObject(micManager))
        
        popover.contentViewController = popupVc
    }
    
    func show(button: NSStatusBarButton){
        DispatchQueue.main.async {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            self.popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func close(){
        DispatchQueue.main.async {
            self.popover.close()
        }
    }
    
    func popoverDidShow(_ notification: Notification) {
        guard let state = recordingManager?.state else {
            return
        }
        if case RecordingState.stopped = state {
            if case CaptureDevice.device(_) = camManager.device {
                if camManager.isGranted {
                    camManager.configureCaptureSession()
                    appDelegate?.showCameraPreview()
                }
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
        if recordingManager?.state != .recording {
            self.appDelegate?.closeCameraPreview()
        }
    }
}
