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
        VStack(alignment: .leading, spacing: 16) {
            Text("Recorder Control Panel").font(.headline)
            
            VStack(spacing: 8){
                DeviceToggle(enabled: $camManager.enabled, device: "Camera")
                DeviceToggle(enabled: $mic.enabled, device: "Microphone")
            }
            
            Button(action: startRecording, label: {
                VStack{
                    Text("Start Recording").padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(4)
            })
            .buttonStyle(PlainButtonStyle())
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
