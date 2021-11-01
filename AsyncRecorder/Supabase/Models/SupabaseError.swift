//
//  SupabaseError.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 01/11/2021.
//

import Foundation

enum SupabaseError: Error {
    case internalServerError(Error)
    case serialization(String)
    case noData
    case server(String, String, String)
    
    func localisedDescription() -> String {
        switch self {
        case let .internalServerError(error):
            return "Internal server error from file request: \(error.localizedDescription)"
        case let .serialization(errorString):
            return "Serialization runtime error from file request: \(errorString)"
        case .noData:
            return "Bad response from server for file request: No data returned."
        case let .server(statusCode, error, message):
            return "Server error from file request. Status code \(statusCode), Error: \(error), Message: \(message)"
        }
    }
}

extension SupabaseError {
    init(json: [String: Any]) throws{
        guard let statusCode = json["statusCode"] as? String else {
            throw RuntimeError("No status code.")
        }
        guard let error = json["error"] as? String else {
            throw RuntimeError("No error.")
        }
        guard let message = json["message"] as? String else {
            throw RuntimeError("No message")
        }
        
        self = .server(statusCode, error, message)
    }
}
