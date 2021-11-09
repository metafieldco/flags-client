//
//  PreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import SwiftUI
import AVKit

struct PreviewView: View {
    
    var action: () -> Void
    var player = AVPlayer(url: URL(string: "https://xopalvvejbbcremeevis.supabase.in/storage/v1/object/public/videos/2bea2358-0871-4ee9-b6d4-f0ab36e564f7/prog_index.m3u8")!)
    @State var hovering = false
    
    var body: some View {
        ZStack{
            
            if hovering {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                    }
                    Spacer()
                }.background(VisualEffectView(material: .popover, blendingMode: .withinWindow)).zIndex(1)
            }
            
            VStack(alignment: .leading) {
                AVPlayerControllerRepresented(player: player)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover{ hovering in
            withAnimation{
                self.hovering = hovering
            }
        }
    }
}
  
struct AVPlayerControllerRepresented : NSViewRepresentable {
    var player : AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView(action: {
            return
        })
    }
}

extension AVPlayerView {

    override open func scrollWheel(with event: NSEvent) {
        // Disable scrolling that can cause accidental video playback control (seek)
        return
    }

    override open func keyDown(with event: NSEvent) {
        // Disable space key (do not pause video playback)

        let spaceBarKeyCode = UInt16(49)
        if event.keyCode == spaceBarKeyCode {
            return
        }
    }

}
