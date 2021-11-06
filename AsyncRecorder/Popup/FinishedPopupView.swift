//
//  FinishedPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 03/11/2021.
//

import SwiftUI

struct FinishedPopupView: View {
    var url: String
    var files: [String]
    var videoID: String
    
    @EnvironmentObject var recording: RecordingStatus
    
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
                    recording.state = .stopped
                }.keyboardShortcut("c", modifiers: [.command, .shift])
                
                ButtonView(text: "Recycle video", color: .gray){
                    let supabase = Supabase()
                    do {
                        try supabase.setup()
                        DispatchQueue.main.asyncAfter(deadline: .now() + Supabase.deleteDelay) {
                            supabase.deleteFolder(body: FileDeleteRequest(prefixes: files))
                            supabase.deleteVideoRecord(uuid: videoID)
                        }
                    }catch{
                        print("Error when recycling files: \(error.localizedDescription). Not showing to the user.")
                    }
                    recording.state = .stopped
                }
            }
        }
    }
}

struct FinishedPopupView_Previews: PreviewProvider {
    static var previews: some View {
        FinishedPopupView(url: "https://test.com", files: ["hello", "farewell"], videoID: "")
    }
}
