//
//  SupabaseSession.swift
//  Flags
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation

struct SupabaseSession {
    private static let tokenKey = "token"
    private static let userIDKey = "userID"
    
    static func signOut() {
        Self.token = nil
        Self.userID = ""
    }

    static var token: Token? {
        get {
            if let token = UserDefaults.standard.object(forKey: tokenKey) as? Data {
                if let decodedToken = try? JSONDecoder().decode(Token.self, from: token) {
                    return decodedToken
                }
            }
            return nil
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: tokenKey)
            }
        }
    }

    static var userID: String {
      get {
        UserDefaults.standard.string(forKey: userIDKey) ?? ""
      }
      set {
        UserDefaults.standard.setValue(newValue, forKey: userIDKey)
      }
    }
}

struct Token: Codable {
    
    let refresh_token: String
    let access_token: String
    
    var expires_at: Date? // populated after decoding by decoding the JWT as gotrue doesn't return it
    
    func isValid(date: Date = Date()) -> Bool {
        guard let expires_at = expires_at else {
            return false
        }
        return date < expires_at
    }
}
