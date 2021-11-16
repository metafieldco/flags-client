//
//  VideoTableInsertRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import Foundation

struct VideoTableInsertRequest: Codable {
    let videoID: String
    let title: String
    let profileID: String
    
    init(videoID: String, profileID: String) {
        self.videoID = videoID
        self.profileID = profileID
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        self.title = "Screen recording - \(dateFormatter.string(from: Date()))"
    }
    
    private enum CodingKeys : String, CodingKey {
        case videoID = "video_id"
        case profileID = "profile_id"
        case title = "title"
    }
}
