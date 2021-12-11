//
//  AuthView.swift
//  Flags
//
//  Created by Archie Edwards on 15/11/2021.
//

import SwiftUI

struct AuthView: View {
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        HStack{
            Spacer()
            VStack {
                Spacer()
                switch authManager.state {
                case .unauthenticated:
                    Text("You're not authenticated").font(.largeTitle)
                    Button(action: {
                        authManager.signInTapped()
                    }, label: {
                        Text("Sign in")
                    })
                case .loading:
                    Text("Authenticating ...")
                case .authenticated:
                    EmptyView()
                }
                Spacer()
            }
            Spacer()
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
