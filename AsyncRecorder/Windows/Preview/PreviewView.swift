//
//  PreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import SwiftUI
import AVKit

struct PreviewView: View {
    
    var url: String
    var videoID: String
    
    @EnvironmentObject var previewManager: PreviewManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            switch previewManager.state {
            case .copied:
                PreviewFeedbackView(msg: "Copied link").zIndex(2)
            case .deleted:
                PreviewFeedbackView(msg: "Recycled video").zIndex(2)
            case .editing:
                PreviewFeedbackView(msg: "Not implemented").zIndex(2)
            case .none:
                PreviewButtonView(url: url, videoID: videoID).zIndex(2)
            }
            
            if previewManager.isHovering || previewManager.state != .none {
                PreviewHoverView().zIndex(1)
            }
            
            if screenshotImage != nil {
                Image(screenshotImage!, scale: 1, label: Text(""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView(url: "", videoID: "")
    }
}
