//
//  FinishedPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 03/11/2021.
//

import SwiftUI

struct FinishedPopupView: View {
    var url: String
    @EnvironmentObject var recording: RecordingStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16){
            HStack(alignment: .center, spacing: 8){
                Image(systemName: "checkmark.circle").foregroundColor(.green).font(.title)
                Text("Video successfully uploaded.").font(.headline)
            }
            
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([.string], owner: nil)
                pasteboard.setString(url, forType: .string)
                recording.state = .stopped
            }, label: {
                VStack{
                    Text("Copy URL to clipboard").padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(4)
            })
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct FinishedPopupView_Previews: PreviewProvider {
    static var previews: some View {
        FinishedPopupView(url: "https://test.com")
    }
}
