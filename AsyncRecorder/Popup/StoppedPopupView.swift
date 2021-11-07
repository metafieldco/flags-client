//
//  StoppedPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct StoppedPopupView: View {
    
    @EnvironmentObject var camManager: CamManager
    @EnvironmentObject var mic: MicManager
    @EnvironmentObject var recordingManager: RecordingManager
    
    var body: some View {
        PopupContainerView{
            Text("Recorder Control Panel").font(.headline)
            
            VStack(spacing: 8){
                DeviceToggle(enabled: $camManager.enabled, device: "Camera")
                DeviceToggle(enabled: $mic.enabled, device: "Microphone")
            }
            
            ButtonView(text: "Start Recording"){
                recordingManager.start()
            }
        }
    }
}
