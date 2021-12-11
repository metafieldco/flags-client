//
//  VideoTableUpdateRequest.swift
//  Flags
//
//  Created by Archie Edwards on 10/11/2021.
//

import Foundation

enum VideoState:String, Codable {
    case uploading = "uploading"
    case recyled = "recycled"
    case active = "active"
}

struct VideoTableUpdateRequest: Codable{
    let state: VideoState
}
