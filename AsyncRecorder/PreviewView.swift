//
//  PreviewView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import SwiftUI

struct PreviewView: View {
    
    @StateObject var viewModel = CameraViewModel()

    var body: some View {
        CameraContainerView(captureSession: viewModel.captureSession)
            .clipShape(Circle())
            .onAppear(perform: { viewModel.checkAuthorization() })
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
}
