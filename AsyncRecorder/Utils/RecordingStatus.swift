//
//  RecordingStatus.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 31/10/2021.
//

import Foundation
import SwiftUI

// Used in ControlView to control state
enum RecordingStatus {
    case Started
    case Stopped
    case Error
}

// Updating a SwiftUI @State variable from swift
func relay(_ binding: Binding<RecordingStatus>, newStatus: RecordingStatus) {
    DispatchQueue.main.async {
        binding.wrappedValue = newStatus
    }
}
