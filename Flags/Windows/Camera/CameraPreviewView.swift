//
//  CameraPreviewView.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: View {
    
    @EnvironmentObject var camManager: CamManager
    @State private var showCamSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if showCamSettings{
                CameraSettingsView().zIndex(2)
            }
            
            VStack{
                EmptyView()
            }
            .frame(width: camManager.size == .fullScreen ? 1000 : 100, height: camManager.size == .fullScreen ? 300 : 150)
            .zIndex(1)
            .onHover{ hovering in
                withAnimation{
                    showCamSettings = hovering
                }
            }
            
            CameraContainerView(previewLayer: camManager.previewLayer)
                .clipShape(camManager.size == .fullScreen ? AnyShape(Rectangle()) : AnyShape(Circle()))
        }
        .onHover { hovering in
            camManager.hovering = hovering
        }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView()
    }
}
