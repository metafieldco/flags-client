//
//  PreviewButtonView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewButtonView: View {
    
    var url: String
    var videoID: String
    
    @EnvironmentObject var previewManager: PreviewManager
    
    var body: some View {
        VStack{
            HStack{
                PreviewImageButton(image: "xmark.bin.fill", action: {
                    Supabase().cleanup(uuid: videoID)
                    withAnimation{
                        previewManager.state = .deleted
                    }
                })
                Spacer()
            }.padding()
            
            Spacer()
            
            HStack{
                PreviewDetailedButton(image: "paintbrush.pointed.fill", text: "Edit"){
                    print("Editing") //TODO: open edit window
                    withAnimation{
                        previewManager.state = .editing
                    }
                }
                Spacer()
                PreviewDetailedButton(image: "doc.on.clipboard", text: "URL"){
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(url, forType: .string)
                    withAnimation{
                        previewManager.state = .copied
                    }
                }
            }.padding()
        }
    }
}

struct PreviewButtonView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewButtonView(url: "", videoID: "")
    }
}
