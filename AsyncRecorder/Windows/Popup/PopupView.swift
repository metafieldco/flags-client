//
//  PopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

//struct PopupView: View {
//    @EnvironmentObject var camManager: CamManager
//    @EnvironmentObject var micManager: MicManager
//    @EnvironmentObject var recordingManager: RecordingManager
//    
//    var body: some View {
//        PopupContainerView{
//            VStack(spacing: 0){
//                DeviceToggle(enabled: $camManager.enabled, device: "Camera")
//                ForEach(camManager.devices, id: \.uniqueID){ cam in
//                    Device(name: cam.localizedName)
//                }
//            }
//            
//            Divider()
//            
//            VStack(spacing: 0){
//                DeviceToggle(enabled: $micManager.enabled, device: "Microphone")
//                ForEach(micManager.devices, id: \.uniqueID){ mic in
//                    Device(name: mic.localizedName)
//                }
//            }
//            
//            Divider()
//            
//            ButtonView(text: "Start Recording"){
//                recordingManager.start()
//            }
//        }
//    }
//}
