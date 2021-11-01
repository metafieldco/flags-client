//
//  RuntimeError.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 31/10/2021.
//

import Foundation

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}
