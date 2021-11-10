//
//  Supabase.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation

class Supabase: NSObject {
    
    private var supabaseStorageUrl: URL?
    private var supabaseTableUrl: URL?
    private var supabaseServiceRoleKey: String?
    
    func setup() throws {
        guard let storageUrlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_STORAGE_URL") as? String, !storageUrlString.isEmpty else {
            throw RuntimeError("SUPABASE_STORAGE_URL not found in the environment.")
        }
        guard let url = URL(string: storageUrlString) else {
            throw RuntimeError("SUPABASE_STORAGE_URL not a valid URL")
        }
        supabaseStorageUrl = url
        
        guard let tableUrlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_TABLE_URL") as? String, !tableUrlString.isEmpty else {
            throw RuntimeError("SUPABASE_TABLE_URL not found in the environment.")
        }
        guard let url = URL(string: tableUrlString) else {
            throw RuntimeError("SUPABASE_TABLE_URL not a valid URL")
        }
        supabaseTableUrl = url
        
        guard let serviceKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String, !serviceKey.isEmpty else {
            throw RuntimeError("SUPABASE_SERVICE_ROLE_KEY not found in the environment.")
        }
        supabaseServiceRoleKey = serviceKey
    }
    
    func cleanup(uuid: String){
        DispatchQueue.global(qos: .background).async {
            do {
                // mark video as recycled - soft delete
                try self.updateVideoRecord(uuid: uuid, updateReq: VideoTableUpdateRequest(recycled: true)){ result in
                    switch result {
                    case .success:
                        print("Successfully marked video for soft deletion with id: \(uuid)")
                    case .failure(let err):
                        print("Error when soft deleting video: \(err) with id: \(uuid)")
                    }
                }
            }catch{
                print("Runtime error when soft deleting video: \(error) with id: \(uuid)")
            }
        }
    }
    
    func uploadFile(bucket: String, uuid: String, filename: String, data: Data?, finish: @escaping (Result<FileUploadSuccess, SupabaseError>) -> Void) throws {
        let temporaryFileURL =
        temporaryDirectoryUrl.appendingPathComponent(filename)
        
        if data != nil {
            // create tmp file
            do {
                try data!.write(to: temporaryFileURL,
                               options: .atomic)
            }catch {
                throw RuntimeError("Failed to create tmp file with err: \(error)")
            }
        }
        
        // configure upload request
        guard supabaseStorageUrl != nil else {
            throw RuntimeError("Supabase storage url is nil.")
        }
        let url = supabaseStorageUrl!.appendingPathComponent(bucket).appendingPathComponent(uuid).appendingPathComponent(filename)
        
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
                do {
                    let errorResponse = try SupabaseError(json: dictionary)
                    finish(.failure(errorResponse))
                    return
                }catch{
                    finish(.failure(.serialization("Couldn't cast data to ErrorResponse: \(error.localizedDescription) Response: \(dictionary)")))
                    return
                }
            }
            
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
    
    func insertVideoRecord(uuid: String, finish: @escaping (Result<String, SupabaseError>) -> Void) throws {
        guard supabaseTableUrl != nil else {
            throw RuntimeError("Supabase table url is nil")
        }
        var request = URLRequest(url: supabaseTableUrl!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        
        guard supabaseServiceRoleKey != nil else {
            throw RuntimeError("Can't create bearer token as api key is nil")
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseServiceRoleKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let jsonData = try? JSONEncoder().encode(VideoTableInsertRequest(videoID: uuid))
        request.httpBody = jsonData
        
        let insertRecordTask = URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error {
                finish(.failure(.internalServerError(error)))
                return
            }
            
            guard let data = data else {
                finish(.failure(.noData))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                    finish(.failure(.serialization("Couldn't cast data as JSON.")))
                    return
                }
                do {
                    let errorResponse = try SupabaseError(json: dictionary)
                    finish(.failure(errorResponse))
                    return
                }catch{
                    finish(.failure(.serialization("Couldn't cast data to ErrorResponse: \(error.localizedDescription) Response: \(dictionary)")))
                    return
                }
            }
            
            finish(.success("All good in da hood"))
        }
        insertRecordTask.resume()
    }
    
    private func updateVideoRecord(uuid: String, updateReq: VideoTableUpdateRequest, finish: @escaping (Result<String, SupabaseError>) -> Void) throws{
        guard supabaseTableUrl != nil else {
            throw RuntimeError("Supabase table url is nil")
        }
        let queryItems = [URLQueryItem(name: "video_id", value: "eq.\(uuid)")]
        var urlComps = URLComponents(string: supabaseTableUrl!.absoluteString)
        urlComps?.queryItems = queryItems
        var request = URLRequest(url: urlComps!.url!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "PATCH"
        
        guard supabaseServiceRoleKey != nil else {
            throw RuntimeError("Can't create bearer token as api key is nil")
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseServiceRoleKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let jsonData = try? JSONEncoder().encode(updateReq)
        request.httpBody = jsonData
        
        let updateRecordTask = URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error {
                finish(.failure(.internalServerError(error)))
                return
            }
            
            guard let data = data else {
                finish(.failure(.noData))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                    finish(.failure(.serialization("Couldn't cast data as JSON.")))
                    return
                }
                do {
                    let errorResponse = try SupabaseError(json: dictionary)
                    finish(.failure(errorResponse))
                    return
                }catch{
                    finish(.failure(.serialization("Couldn't cast data to ErrorResponse: \(error.localizedDescription) Response: \(dictionary)")))
                    return
                }
            }
            
            finish(.success("All good in da hood"))
        }
        updateRecordTask.resume()
    }
}
