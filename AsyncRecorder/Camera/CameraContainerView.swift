//
//  CameraContainerView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import SwiftUI
import AVFoundation

/*
 This class wraps CameraView so we can use it in SwiftUI
*/
final class CameraContainerView: NSViewRepresentable {
    typealias NSViewType = CameraView

    let captureSession: AVCaptureSession

    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    func makeNSView(context: Context) -> CameraView {
        return CameraView(captureSession: captureSession)
    }

    func updateNSView(_ nsView: CameraView, context: Context) { }
}

class CameraView: NSView {
    
    var previewLayer: AVCaptureVideoPreviewLayer?

    init(captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(frame: .zero)

        setupLayer()
    }

    func setupLayer() {

        previewLayer?.frame = self.frame
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        layer = previewLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
