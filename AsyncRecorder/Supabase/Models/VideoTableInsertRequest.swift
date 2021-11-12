//
//  VideoTableInsertRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import Foundation

struct VideoTableInsertRequest: Codable {
    let videoID: String
    let title = "I love Archie"
    let profileID = "0fbbf933-1f8a-4d0d-bbf1-ce086a61689b"
    
    private enum CodingKeys : String, CodingKey {
        case videoID = "video_id"
        case profileID = "profile_id"
        case title = "title"
    }
}
