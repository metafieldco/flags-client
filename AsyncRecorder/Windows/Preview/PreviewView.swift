//
//  PreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import SwiftUI
import AVKit

struct PreviewView: View {
    
    @EnvironmentObject var previewManager: PreviewManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            PreviewButtonView().zIndex(2)
            
            if previewManager.isHovering {
                PreviewHoverView().zIndex(1)
            }
            
            Image("ScreenshotImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }.clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
}

//struct AVPlayerControllerRepresented : NSViewRepresentable {
//    var player : AVPlayer
//
//    func makeNSView(context: Context) -> AVPlayerView {
//        let view = AVPlayerView()
//        view.controlsStyle = .none
//        view.player = player
//        return view
//    }
//
//    func updateNSView(_ nsView: AVPlayerView, context: Context) {
//
//    }
//}
//
//extension AVPlayerView {
//
//    override open func scrollWheel(with event: NSEvent) {
//        // Disable scrolling that can cause accidental video playback control (seek)
//        return
//    }
//
//    override open func keyDown(with event: NSEvent) {
//        // Disable space key (do not pause video playback)
//
//        let spaceBarKeyCode = UInt16(49)
//        if event.keyCode == spaceBarKeyCode {
//            return
//        }
//    }
//
//}
