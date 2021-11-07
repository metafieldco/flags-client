//
//  FileListSuccess.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 07/11/2021.
//

import Foundation

struct FileListSuccess {
    let name: String
}

extension FileListSuccess {
    init(json: [String: Any]) throws{
        guard let name = json["name"] as? String else {
            throw RuntimeError("No name.")
        }
        self.name = name
    }
}
