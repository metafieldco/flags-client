//
//  AuthManager.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation
import AuthenticationServices
import JWTDecode

class AuthManager: NSObject, ObservableObject{
    
    enum AuthState {
        case loading
        case authenticated
        case unauthenticated
    }
    
    @Published var state: AuthState {
        didSet {
            if state == .authenticated {
                // dismiss window
                delegate?.deleteAuthWindow()
            }else if state == .unauthenticated {
                delegate?.showAuthWindow()
            }
        }
    }
    
    weak private var delegate: AppDelegate?
    private var refreshTokenUrl: URL
    private var loginUrl: URL
    private var scheme: String
    private var anonKey: String
    
    init(_ delegate: AppDelegate) {
        if SupabaseSession.token != nil {
            self.state = .authenticated
        }else{
            self.state = .unauthenticated
        }
        self.delegate = delegate
        
        var queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        var urlComps = URLComponents(string: URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_TOKEN_URL") as! String)!.absoluteString)!
        urlComps.queryItems = queryItems
        self.refreshTokenUrl = urlComps.url!
        
        self.scheme = "client"
        queryItems = [URLQueryItem(name: "scheme", value: self.scheme)]
        urlComps = URLComponents(string: URL(string: Bundle.main.object(forInfoDictionaryKey: "WEB_APP_URL") as! String)!.appendingPathComponent("login").absoluteString)!
        urlComps.queryItems = queryItems
        loginUrl = urlComps.url!
        
        self.anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
        
        super.init()
    }
    
    func signInTapped() {
        let authenticationSession = ASWebAuthenticationSession(url: loginUrl, callbackURLScheme: self.scheme) { [weak self] callbackURL, error in
            guard
                error == nil,
                let callbackURL = callbackURL,
                let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
                let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
                let expiresAt = queryItems.first(where: { $0.name == "expires_at" })?.value,
                let expiresAtDouble = Double(expiresAt),
                let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value,
                let userID = queryItems.first(where: { $0.name == "user_id" })?.value
            else {
                DispatchQueue.main.async {
                    self?.state = .unauthenticated
                }
                return
            }
            
            SupabaseSession.token = Token(refresh_token: refreshToken, access_token: accessToken, expires_at: Date(timeIntervalSince1970: expiresAtDouble))
            SupabaseSession.userID = userID
            
            DispatchQueue.main.async {
                self?.state = .authenticated
                self?.delegate?.showPopover(nil)
            }
        }

        authenticationSession.presentationContextProvider = self
        authenticationSession.prefersEphemeralWebBrowserSession = true

        if !authenticationSession.start() {
            print("Failed to start ASWebAuthenticationSession")
        }
        
        DispatchQueue.main.async {
            self.state = .loading
        }
    }
    
    func refreshToken() {
        guard let token = SupabaseSession.token else{
            DispatchQueue.main.async {
                self.state = .unauthenticated
            }
            return
        }
        // Hacky but jwt won't expire for 2 hours, and there is a limit of 1 hour so this check should work fine for now.
        if token.isValid(date: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!) {
            return
        }
        
        // refresh token
        print("Refreshing token")
        var request = URLRequest(url: refreshTokenUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(RefreshRequest(refresh_token: token.refresh_token))
        
        URLSession.shared.networkRequest(request: request, token: nil){ [weak self] result in
            switch result {
            case .success(let data):
                do {
                    var token = try JSONDecoder().decode(Token.self, from: data)
                    if let jwt = try? decode(jwt: token.access_token){
                        token.expires_at = jwt.expiresAt
                    }
                    print("Got new token")
                    SupabaseSession.token = token
                }catch{
                    SupabaseSession.signOut()
                    DispatchQueue.main.async {
                        self?.state = .unauthenticated
                    }
                    print("Failed to decode into refresh token: \(error.localizedDescription)")
                }
            case .failure(let error):
                SupabaseSession.signOut()
                DispatchQueue.main.async {
                    self?.state = .unauthenticated
                }
                print("Error when refreshing token: \(error)")
            }
            
        }
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession)
  -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
}

