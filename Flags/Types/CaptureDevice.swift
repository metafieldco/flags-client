//
//  CaptureDevice.swift
//  Flags
//
//  Created by Archie Edwards on 11/12/2021.
//

import Foundation
import AVFoundation

enum CaptureDevice: Equatable {
    case empty(String) // so we can have no device in popover
    case device(AVCaptureDevice)
    
    var localizedName: String {
        switch self {
        case .empty(let text):
            return text
        case .device(let device):
            return device.localizedName
        }
    }
    
    var uniqueID: String {
        switch self {
        case .empty(let text):
            return text
        case .device(let device):
            return device.uniqueID
        }
    }
}

let noMicrophone: CaptureDevice = .empty("No microphone")
let noCamera: CaptureDevice = .empty("No camera")
