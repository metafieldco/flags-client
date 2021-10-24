//
//  CameraContainerView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
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
