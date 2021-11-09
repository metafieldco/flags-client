//
//  ButtonView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 06/11/2021.
//

import SwiftUI

struct ButtonView: View {
    var text: String
    var color = Color.blue
    
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack{
                Text(text).padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(4)
        })
        .buttonStyle(PlainButtonStyle())
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(text: "Copy to clipboard"){
            print("hello world")
        }
    }
}
