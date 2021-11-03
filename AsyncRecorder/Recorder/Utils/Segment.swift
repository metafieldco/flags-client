//
//  Segment.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AVFoundation

// This is a simple structure that combines the output of AVAssetWriterDelegate with an increasing segment index.
struct Segment {
    let index: Int
    let data: Data
    let isInitializationSegment: Bool
    let report: AVAssetSegmentReport?
}

extension Segment {
    func fileName(forPrefix prefix: String) -> String {
        let fileExtension: String
        if isInitializationSegment {
            fileExtension = "mp4"
        } else {
            fileExtension = "m4s"
        }
        return "\(prefix)\(index).\(fileExtension)"
    }
}
