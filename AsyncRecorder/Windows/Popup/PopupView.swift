//
//  PopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct PopupView: View {
    var body: some View {
        VStack(){
            StoppedPopupView()
        }
        .frame(width: 250)
        .padding()
        .onAppear{
            print("Popup view appearing.")
        }
        .onDisappear{
            print("Popup view dissapearing.")
        }
    }
}
