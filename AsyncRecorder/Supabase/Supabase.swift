//
//  Supabase.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
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
    
    func uploadFile(uuid: UUID, filename: String, data: Data, finish: @escaping (Result<FileUploadSuccess, SupabaseError>) -> Void) throws {
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
            throw RuntimeError("Supabase storage url is nil.")
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
                    let errorResponse = try SupabaseError(json: dictionary)
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
    
    func deleteFolder(uuid: UUID, body: FileDeleteRequest) {
        print(body.prefixes)
        // configure delete request
        guard supabaseStorageUrl != nil else {
            print("Supabase storage url is nil")
            return
        }
        var request = URLRequest(url: supabaseStorageUrl!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "DELETE"
        
        guard supabaseServiceRoleKey != nil else {
            print("Can't create bearer token as api key is nil")
            return
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONEncoder().encode(body)
        request.httpBody = jsonData
        
        let deleteTask = URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error {
                print("Internal server error when deleting folder: \(error)")
                return
            }
            
            guard let data = data else {
                print("Bad response from server when deleting folder. No data.")
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
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                    print("Couldn't cast response to JSON [String: Any] when deleting folder.")
                    return
                }
                do {
                    let errorResponse = try SupabaseError(json: dictionary)
                    print(errorResponse.localisedDescription())
                    return
                }catch{
                    print("Couldn't cast data to ErrorResponse: \(error.localizedDescription) Response: \(dictionary)")
                    return
                }
            }
            
            // we were successful if the array in the response is the same length as the amount of segment files we sent to be deleted.
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let array = json as? [Any] else {
                print("Couldn't cast response to Array of structs when deleting folder.")
                return
            }
            if array.count == body.prefixes.count {
                print("Successfully deleted folder from s3")
            }else{
                print("Failed to delete folder from s3. Response length did not match body. Response count: \(array.count), Body count: \(body.prefixes.count)")
            }
        }
        deleteTask.resume()
    }
}
