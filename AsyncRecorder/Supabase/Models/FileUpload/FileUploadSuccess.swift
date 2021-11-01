//
//  SuccessResponse.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 01/11/2021.
//

import Foundation

struct FileUploadSuccess{
    let key: String
}

extension FileUploadSuccess {
    init(json: [String: Any]) throws{
        guard let key = json["Key"] as? String else {
            throw RuntimeError("No key.")
        }
        self.key = key
    }
}
