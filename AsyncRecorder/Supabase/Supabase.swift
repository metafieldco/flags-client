//
//  Streamer.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 31/10/2021.
//

import Foundation

class Supabase: NSObject {
    
    private var supabaseStorageUrl: URL?
    private var supabaseServiceRoleKey: String?
    
    private lazy var temporaryDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(),
                                                isDirectory: true)
    
    func setup() throws {
        guard let storageUrlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_STORAGE_URL") as? String, !storageUrlString.isEmpty else {
            throw RuntimeError("SUPABASE_STORAGE_URL not found in the environment.")
        }
        guard let url = URL(string: storageUrlString) else {
            throw RuntimeError("SUPABASE_STORAGE_URL not a valid URL")
        }
        supabaseStorageUrl = url
        
        guard let serviceKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String, !serviceKey.isEmpty else {
            throw RuntimeError("SUPABASE_SERVICE_ROLE_KEY not found in the environment.")
        }
        supabaseServiceRoleKey = serviceKey
    }
    
    func uploadFile(uuid: UUID, filename: String, data: Data, finish: @escaping (Result<FileUploadSuccess, FileUploadError>) -> Void) throws {
        // create tmp file
        let temporaryFileURL =
        temporaryDirectoryUrl.appendingPathComponent(filename)
        do {
            try data.write(to: temporaryFileURL,
                           options: .atomic)
        }catch {
            throw RuntimeError("Failed to create tmp file with err: \(error)")
        }
        
        // configure upload request
        guard supabaseStorageUrl != nil else {
            throw RuntimeError("Supabase storage url is null. This shouldn't ever happen here.")
        }
        let url = supabaseStorageUrl!.appendingPathComponent(uuid.uuidString).appendingPathComponent(filename)
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        
        guard supabaseServiceRoleKey != nil else {
            throw RuntimeError("Can't create bearer token as api key is nil")
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        
        // make upload request
        let uploadTask = URLSession.shared.uploadTask(with: request, fromFile: temporaryFileURL) { data, response, error in
            if let error = error {
                finish(.failure(.internalServerError(error)))
                return
            }
            
            // Response should always have data
            guard let data = data else {
                finish(.failure(.noData))
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                finish(.failure(.serialization("Couldn't cast data as JSON.")))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                /*
                 {
                   "statusCode": "string",
                   "error": "string",
                   "message": "string"
                 }
                 */
                do {
                    let errorResponse = try FileUploadError(json: dictionary)
                    finish(.failure(errorResponse))
                    return
                }catch{
                    finish(.failure(.serialization("Couldn't cast data to ErrorResponse: \(error.localizedDescription) Response: \(dictionary)")))
                    return
                }
            }
            
            /*
             {
               "Key": "string"
             }
             */
            do {
                let successResponse = try FileUploadSuccess(json: dictionary)
                finish(.success(successResponse))
                return
            }catch{
                finish(.failure(.serialization("Couldn't cast to SuccessResponse: \(error.localizedDescription) Response: \(dictionary)")))
                return
            }
        }
        uploadTask.resume()
    }
    
    func deleteFolder(uuid: UUID) {
        // TODO: delete folder from supabase to cleanup
        print("not implemented.")
    }
}
