//
//  ControlView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import SwiftUI

struct ControlView: View {
    
    @State var recordingStatus = ""
    private let recorder = Recorder()
    
    var body: some View {
        VStack{
            Text(recordingStatus)
            HStack{
                Button(action: { recorder.start() }, label: { Text ("Record")} )
                Button(action: { recorder.stop() }, label: { Text("Stop recording")} )
            }
        }
    }
}

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView()
    }
}
