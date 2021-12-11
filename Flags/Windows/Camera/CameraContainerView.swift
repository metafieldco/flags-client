//
//  CameraContainerView.swift
//  Flags
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

    let previewLayer: AVCaptureVideoPreviewLayer

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
    }

    func makeNSView(context: Context) -> CameraView {
        return CameraView(previewLayer: previewLayer)
    }

    func updateNSView(_ nsView: CameraView, context: Context) { }
}

class CameraView: NSView {
    
    let previewLayer: AVCaptureVideoPreviewLayer

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        super.init(frame: .zero)

        setupLayer()
    }

    func setupLayer() {

        previewLayer.frame = self.frame
        previewLayer.contentsGravity = .resizeAspectFill
        previewLayer.videoGravity = .resizeAspectFill
        
        self.layer = self.previewLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
