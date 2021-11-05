//
//  VideoTableInsertRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import Foundation

struct VideoTableInsertRequest: Codable {
    let videoID: String
    
    private enum CodingKeys : String, CodingKey {
        case videoID = "video_id"
    }
}
