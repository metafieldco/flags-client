//
//  CameraPreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct CameraPreviewView: View {
    private var session = CameraSession()

    var body: some View {
        CameraContainerView(captureSession: session.captureSession)
            .clipShape(Circle())
            .onAppear{
                session.prepareCamera()
            }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView()
    }
}
