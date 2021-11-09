//
//  PreviewButtonView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewButtonView: View {
    var body: some View {
        VStack{
            HStack{
                PreviewImageButton(image: "xmark.bin.fill", action: {
                    return
                })
                Spacer()
            }.padding()
            
            Spacer()
            
            HStack{
                PreviewDetailedButton(image: "paintbrush.pointed.fill", text: "Edit"){
                    print("Editing")
                }
                Spacer()
                PreviewDetailedButton(image: "doc.on.clipboard", text: "URL"){
                    print("Copy link")
                }
            }.padding()
        }
    }
}

struct PreviewButtonView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewButtonView()
    }
}
