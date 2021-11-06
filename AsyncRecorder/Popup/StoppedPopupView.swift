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
    @EnvironmentObject var recording: RecordingStatus
    
    var capture : Capture?
    
    var body: some View {
        PopupContainerView{
            Text("Recorder Control Panel").font(.headline)
            
            VStack(spacing: 8){
                DeviceToggle(enabled: $camManager.enabled, device: "Camera")
                DeviceToggle(enabled: $mic.enabled, device: "Microphone")
            }
            
            ButtonView(text: "Start Recording"){
                startRecording()
            }
        }
    }
    
    private func startRecording(){
        guard let capture = capture else {
            return
        }
        do {
            recording.state = .recording
            try capture.start()
        }catch{
            print(error)
            recording.state = .error
        }
    }
}

struct StoppedPopupView_Previews: PreviewProvider {
    static var previews: some View {
        StoppedPopupView(capture: nil)
    }
}
