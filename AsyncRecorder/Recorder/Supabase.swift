//
//  Streamer.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 31/10/2021.
//

import Foundation

class Supabase: NSObject {
    
    private var supabaseStorageUrl: String?
    private var supabaseServiceRoleKey: String?
    
    private lazy var temporaryDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(),
                                                isDirectory: true)
    
    func setup() throws {
        guard let storageUrl = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_STORAGE_URL") as? String, !storageUrl.isEmpty else {
            throw RuntimeError("SUPABASE_STORAGE_URL not found in the environment.")
        }
        supabaseStorageUrl = storageUrl
        
        guard let serviceKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String, !serviceKey.isEmpty else {
            throw RuntimeError("SUPABASE_SERVICE_ROLE_KEY not found in the environment.")
        }
        supabaseServiceRoleKey = serviceKey
    }
    
    func uploadFile(uuid: UUID, filename: String, data: Data, finish: @escaping (RuntimeError?) -> Void) throws {
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
        guard supabaseStorageUrl != nil, var url = URL(string: supabaseStorageUrl!) else {
            throw RuntimeError("Failed to create URL with supabase storage url: \(supabaseStorageUrl ?? "")")
        }
        url = url.appendingPathComponent(uuid.uuidString).appendingPathComponent(filename)
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
                finish(RuntimeError("Error from upload file request: \(error.localizedDescription)"))
                return
            }
            guard let _ = response as? HTTPURLResponse else {
                finish(RuntimeError("Bad response from server when uploading file."))
                return
            }
            finish(nil) //TODO: do more validation over response returned
        }
        uploadTask.resume()
    }
    
    func deleteFolder(uuid: UUID) {
        // TODO: delete folder from supabase to cleanup
        print("not implemented.")
    }
}
