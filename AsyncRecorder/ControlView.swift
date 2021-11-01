//
//  ControlView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import SwiftUI

struct ControlView: View {
    
    @State private var recordingStatus: RecordingStatus = .Stopped
    @State private var capture : Capture?
    
    var body: some View {
        VStack{
            if recordingStatus == .Error {
                Text("An unexpected error occured. Try and restart the application.")
            }
            Button(action: trigger, label: {
                if recordingStatus == .Stopped {
                    Text("Record")
                }else{
                    Text("Stop")
                }
            } )
        }.onAppear(perform: {
            capture = Capture(recordingStatus: $recordingStatus)
        })
    }
    
    private func trigger () {
        if recordingStatus == .Error {
            return
        }
        if recordingStatus == .Stopped {
            do {
                try capture?.start()
                recordingStatus = .Started
            }catch {
                print(error)
                recordingStatus = .Error
            }
        }else {
            capture?.stop()
            recordingStatus = .Stopped
        }
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView()
    }
}
