//
//  FileDeleteRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation

struct FileDeleteRequest: Codable {
    let prefixes: [String]
}
