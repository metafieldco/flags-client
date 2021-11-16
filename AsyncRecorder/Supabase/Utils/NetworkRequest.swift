//
//  NetworkRequest.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation

extension URLSession {
    func networkRequest(request: URLRequest, token: Token?, completion: @escaping (Result<Data, ServiceError>) -> Void) {
        var request = request
        if let token = token {
            request.setValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ServiceError(message: "Internal server error: \(error.localizedDescription)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(ServiceError(message: "No data")))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                let error = String(decoding: data, as: UTF8.self)
                completion(.failure(ServiceError(message: error)))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    func networkFileRequest(request: URLRequest, fileUrl: URL, token: Token?, completion: @escaping (Result<Data, ServiceError>) -> Void) {
        var request = request
        if let token = token {
            request.setValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = uploadTask(with: request, fromFile: fileUrl) { data, response, error in
            if let error = error {
                completion(.failure(ServiceError(message: "Internal server error: \(error.localizedDescription)")))
                return
            }
            
            guard let data = data else {
                completion(.failure(ServiceError(message: "No data")))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                let error = String(decoding: data, as: UTF8.self)
                completion(.failure(ServiceError(message: error)))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
}
