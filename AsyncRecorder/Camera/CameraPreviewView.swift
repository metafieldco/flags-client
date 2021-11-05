//
//  CameraPreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct CameraPreviewView: View {
    
    @EnvironmentObject var camManager: CamManager
    @State private var showCamSettings = false
    @State private var done = false
    
    private var session = CameraSession()

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
            
            CameraContainerView(captureSession: session.captureSession)
                .clipShape(camManager.size == .fullScreen ? AnyShape(Rectangle()) : AnyShape(Circle()))
        }
        .onAppear{
            session.prepareCamera()
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
