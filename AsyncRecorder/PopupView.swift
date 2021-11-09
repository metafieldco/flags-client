//
//  PopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct PopupView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    
    var body: some View {
        VStack(){
            switch recordingManager.state {
            case .stopped, .recording, .finished(_,_):
                StoppedPopupView()
            case .error:
                ErrorPopupView()
            }
            
        }
        .frame(width: 250)
        .padding()
        .onAppear{
            print("Popup view appearing.")
        }
        .onDisappear{
            print("Popup view dissapearing.")
        }
    }
}
