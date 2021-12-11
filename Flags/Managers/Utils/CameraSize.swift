//
//  CameraModels.swift
//  Flags
//
//  Created by Archie Edwards on 04/11/2021.
//

import Foundation
import SwiftUI

struct CameraSizeButtonDetails {
    let systemName: String
    let font: Font
}

enum CameraSize: String, Equatable, CaseIterable {
    case regular = "Regular"
    case large = "Large"
    case fullScreen = "Full Screen"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
    
    var buttonDetails: CameraSizeButtonDetails {
        switch self {
        case .regular:
            return CameraSizeButtonDetails(systemName: "circle.fill", font: .subheadline)
        case .large:
            return CameraSizeButtonDetails(systemName: "circle.fill", font: .title2)
        case .fullScreen:
            return CameraSizeButtonDetails(systemName: "arrow.up.left.and.arrow.down.right", font: .title2)
        }
    }
    
    var width: Int {
        switch self {
        case .regular:
            return 360
        case .large, .fullScreen:
            return 480
        }
    }
    
    var height: Int {
        switch self {
        case .regular:
            return 225
        case .large, .fullScreen:
            return 300
        }
    }
}
