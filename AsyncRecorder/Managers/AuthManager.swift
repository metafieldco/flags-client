//
//  AuthManager.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 15/11/2021.
//

import Foundation
import AuthenticationServices

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
    
    init(_ delegate: AppDelegate) {
        if SupabaseSession.token != nil {
            self.state = .authenticated
        }else{
            self.state = .unauthenticated
        }
        self.delegate = delegate
        
        super.init()
    }
    
    func signInTapped() {
        // Use the URL and callback scheme specified by the authorization provider.
        let scheme = "buttercup"
        guard let authURL = URL(string: "http://localhost:3000/login?scheme=\(scheme)") else {
            DispatchQueue.main.async {
                self.state = .unauthenticated
            }
            return
        }

        let authenticationSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { [weak self] callbackURL, error in
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
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession)
  -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
}

