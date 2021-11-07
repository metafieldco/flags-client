//
//  FileListRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 07/11/2021.
//

import Foundation

struct FileListRequest: Encodable {
    let limit = 100
    let offset = 0
    let sortBy = sortByField()
    let prefix: String
    
    struct sortByField: Encodable {
        let column = "name"
        let order = "asc"
    }
}
