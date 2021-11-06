//
//  PopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct PopupView: View {
    var capture: Capture?
    @EnvironmentObject var recording: RecordingStatus
    
    var body: some View {
        VStack(){
            switch recording.state {
            case .stopped, .recording:
                StoppedPopupView(capture: capture)
            case let .finished(url, files, videoID):
                FinishedPopupView(url: url, files: files, videoID: videoID)
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

struct PopupView_Previews: PreviewProvider {
    static var previews: some View {
        PopupView(capture: nil)
    }
}
