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
        // give supabase a chance to propogate
        DispatchQueue.main.asyncAfter(deadline: .now() + deleteDelay){
            do {
                // get all files from storage
                try self.listFolder(uuid: uuid){ result in
                    switch result {
                    case .success(let req):
                        self.deleteFolder(body: req) // ignore any errors here
                    case .failure(let error):
                        print("Failed to list folder: \(error.localisedDescription())")
                    }
                }
                // delete record (if it doesn't exist still returns 204)
                self.deleteVideoRecord(uuid: uuid)
            }catch{
                print("RuntimeError when cleaning up: \(error)")
            }
        }
    }
    
    func uploadFile(uuid: String, filename: String, data: Data, finish: @escaping (Result<FileUploadSuccess, SupabaseError>) -> Void) throws {
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
    
    private func listFolder(uuid: String, finish: @escaping (Result<FileDeleteRequest, SupabaseError>) -> Void) throws {
        // configure upload request
        guard supabaseStorageUrl != nil else {
            throw RuntimeError("Supabase storage url is nil.")
        }
        let url = supabaseStorageUrl!.appendingPathComponent(listBucket)
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        
        guard supabaseServiceRoleKey != nil else {
            throw RuntimeError("Can't create bearer token as api key is nil")
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONEncoder().encode(FileListRequest(prefix: uuid))
        request.httpBody = jsonData
        
        // make upload request
        let listTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                finish(.failure(.internalServerError(error)))
                return
            }
            
            // Response should always have data
            guard let data = data else {
                finish(.failure(.noData))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                    finish(.failure(.serialization("Couldn't cast response to JSON [String: Any] when listing storage folder.")))
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
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [[String: Any]] else {
                finish(.failure(.serialization("Couldn't cast data as JSON array")))
                return
            }
            var prefixes = [String]()

            do {
                for item in dictionary {
                    let file = try FileListSuccess(json: item)
                    prefixes.append("\(uuid)/\(file.name)")
                }
                finish(.success(FileDeleteRequest(prefixes: prefixes)))
            }catch{
                finish(.failure(.serialization("Couldn't cast data to FileListSuccess: \(error.localizedDescription) Response: \(dictionary)")))
                return
            }
        }
        listTask.resume()
    }
    
    private func deleteFolder(body: FileDeleteRequest) {
        // configure delete request
        guard supabaseStorageUrl != nil else {
            print("Supabase storage url is nil")
            return
        }
        var request = URLRequest(url: supabaseStorageUrl!.appendingPathComponent(bucket),
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
    
    private func deleteVideoRecord(uuid: String) {
        // configure delete request
        guard supabaseTableUrl != nil else {
            print("Supabase table url is nil")
            return
        }
        let queryItems = [URLQueryItem(name: "video_id", value: "eq.\(uuid)")]
        var urlComps = URLComponents(string: supabaseTableUrl!.absoluteString)
        urlComps?.queryItems = queryItems
        var request = URLRequest(url: urlComps!.url!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "DELETE"
        
        guard supabaseServiceRoleKey != nil else {
            print("Can't create bearer token as api key is nil")
            return
        }
        request.setValue( "Bearer \(supabaseServiceRoleKey!)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseServiceRoleKey, forHTTPHeaderField: "apikey")
        
        let deleteTask = URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error {
                print("Internal server error when deleting video record: \(error)")
                return
            }
            
            guard let data = data else {
                print("Bad response from server when deleting video record. No data.")
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let dictionary = json as? [String: Any] else {
                    print("Couldn't cast response to JSON [String: Any] when deleting video record.")
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
            print("Successfully deleted video record with video_id: \(uuid)")
        }
        deleteTask.resume()
    }
}
