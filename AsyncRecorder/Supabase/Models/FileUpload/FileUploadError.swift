//
//  ErrorResponse.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 01/11/2021.
//

import Foundation

enum FileUploadError: Error {
    case internalServerError(Error)
    case serialization(String)
    case noData
    case server(String, String, String)
    
    func localisedDiscription() -> String {
        switch self {
        case let .internalServerError(error):
            return "Internal server error from upload file request: \(error.localizedDescription)"
        case let .serialization(errorString):
            return "Serialization runtime error when uploading file: \(errorString)"
        case .noData:
            return "Bad response from server when uploading file: No data returned."
        case let .server(statusCode, error, message):
            return "Server error from upload file request. Status code \(statusCode), Error: \(error), Message: \(message)"
        }
    }
}

extension FileUploadError {
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
