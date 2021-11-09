//
//  FinishedPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 03/11/2021.
//

import SwiftUI

struct FinishedPopupView: View {
    var url: String
    var videoID: String
    
    @EnvironmentObject var recordingManager: RecordingManager
    
    var body: some View {
        PopupContainerView{
            HStack(alignment: .center, spacing: 8){
                Image(systemName: "checkmark.circle").foregroundColor(.green).font(.title)
                Text("Video successfully uploaded.").font(.headline)
            }
            
            VStack(spacing: 8){
                ButtonView(text: "Copy to clipboard"){
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(url, forType: .string)
                    recordingManager.state = .stopped
                }.keyboardShortcut("c", modifiers: [.command, .shift])
                
                ButtonView(text: "Recycle video", color: .gray){
                    let supabase = Supabase()
                    do {
                        try supabase.setup()
                        supabase.cleanup(uuid: videoID)
                    }catch{
                        print("Error when recycling files: \(error.localizedDescription). Not showing to the user.")
                    }
                    recordingManager.state = .stopped
                }
            }
        }
    }
}

struct FinishedPopupView_Previews: PreviewProvider {
    static var previews: some View {
        FinishedPopupView(url: "https://test.com", videoID: "")
    }
}
