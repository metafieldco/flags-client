//
//  StoppedPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct StoppedPopupView: View {
    
    @EnvironmentObject var facecam: CamManager
    @EnvironmentObject var mic: MicManager
    @EnvironmentObject var recording: RecordingStatus
    
    var capture : Capture?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recorder Control Panel").font(.headline)
            
            VStack(spacing: 8) {
                Toggle(isOn: $facecam.enabled, label: {
                    Text("Facecam")
                    Spacer()
                })
                    .frame(maxWidth: .infinity)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Toggle(isOn: $mic.enabled, label: {
                    Text("Microphone")
                    Spacer()
                })
                    .frame(maxWidth: .infinity)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
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
