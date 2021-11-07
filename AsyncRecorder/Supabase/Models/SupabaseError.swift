//
//  SupabaseError.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation

enum SupabaseError: Error {
    case internalServerError(Error)
    case serialization(String)
    case noData
    case server(String)
    
    func localisedDescription() -> String {
        switch self {
        case let .internalServerError(error):
            return "Internal server error from file storage request: \(error.localizedDescription)"
        case let .serialization(errorString):
            return "Serialization runtime error from file storage request: \(errorString)"
        case .noData:
            return "Bad response from server for file storage request: No data returned."
        case let .server(message):
            return "Server error from file storage. Message: \(message)"
        }
    }
}

extension SupabaseError {
    init(json: [String: Any]) throws{
        guard let message = json["message"] as? String else {
            throw RuntimeError("No message")
        }
        
        self = .server(message)
    }
}
