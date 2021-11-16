//
//  Supabase.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation

class Supabase: NSObject {
    
    private var supabaseStorageUrl: URL
    private var supabaseTableUrl: URL
    private var supabaseAnonKey: String
    
    private let videoBucket = "videos"
    private let thumbnailBucket = "thumbnails"
    private let temporaryDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(),
                                                isDirectory: true)
    
    enum Bucket: String {
        case videos = "videos"
        case thumbnails = "thumbnails"
    }
    
    override init() {
        supabaseStorageUrl = URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_STORAGE_URL") as! String)!
        supabaseTableUrl = URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_TABLE_URL") as! String)!
        supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
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
    
    func uploadVideoFile(uuid: String, filename: String, data: Data, completion: @escaping (Result<Bool, ServiceError>) -> Void) throws {
        // Create tmp file
        let temporaryFileURL =
        temporaryDirectoryUrl.appendingPathComponent(filename)
        do {
            try data.write(to: temporaryFileURL,
                           options: .atomic)
        }catch {
            throw RuntimeError("Failed to create tmp file with err: \(error)")
        }
        
        // Create request
        let url = supabaseStorageUrl.appendingPathComponent(Bucket.videos.rawValue).appendingPathComponent(uuid).appendingPathComponent(filename)
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        URLSession.shared.networkFileRequest(request: request, fileUrl: temporaryFileURL, token: SupabaseSession.token){ result in
            switch result{
            case .success(_):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func uploadThumbnailFile(uuid: String, filename: String, completion: @escaping (Result<Bool, ServiceError>) -> Void) throws {
        // Reference existing tmp file
        let temporaryFileURL =
        temporaryDirectoryUrl.appendingPathComponent(filename)
        
        // Create request
        let url = supabaseStorageUrl.appendingPathComponent(Bucket.thumbnails.rawValue).appendingPathComponent(uuid).appendingPathComponent(filename)
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.networkFileRequest(request: request, fileUrl: temporaryFileURL, token: SupabaseSession.token){ result in
            switch result{
            case .success(_):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func insertVideoRecord(uuid: String, completion: @escaping (Result<Bool, ServiceError>) -> Void) throws {
        var request = URLRequest(url: supabaseTableUrl,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONEncoder().encode(VideoTableInsertRequest(videoID: uuid, profileID: SupabaseSession.userID))
        
        URLSession.shared.networkRequest(request: request, token: SupabaseSession.token) { result in
            switch result {
            case .success(_):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateVideoRecord(uuid: String, updateReq: VideoTableUpdateRequest, completion: @escaping (Result<Bool, ServiceError>) -> Void) throws{

        let queryItems = [URLQueryItem(name: "video_id", value: "eq.\(uuid)")]
        var urlComps = URLComponents(string: supabaseTableUrl.absoluteString)
        urlComps?.queryItems = queryItems
        var request = URLRequest(url: urlComps!.url!,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "PATCH"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONEncoder().encode(updateReq)
        
        URLSession.shared.networkRequest(request: request, token: SupabaseSession.token){ result in
            switch result {
            case .success(_):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
