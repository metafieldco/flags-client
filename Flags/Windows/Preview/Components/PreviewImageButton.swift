//
//  PreviewImageButton.swift
//  Flags
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewImageButton: View {
    var image: String
    var action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var previewManager: PreviewManager
    
    var body: some View{
        if previewManager.isHovering {
            Button(action: {
                action()
            }, label: {
                Image(systemName: image)
                    .padding(12)
                    .font(.title3)
                    .background(Color.secondary)
                    .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                    .cornerRadius(256)
            })
                .buttonStyle(PlainButtonStyle())
        }else{
            Button(action: {
                action()
            }, label: {
                Image(systemName: image)
                    .padding(12)
                    .font(.title3)
                    .background(BlurEffect(material: .toolTip, blendingMode: .withinWindow))
                    .foregroundColor(.primary)
                    .cornerRadius(256)
            })
                .buttonStyle(PlainButtonStyle())
        }
        
    }
}

struct PreviewImageButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewImageButton(image: "xmark.bin.fill", action: { return })
    }
}
