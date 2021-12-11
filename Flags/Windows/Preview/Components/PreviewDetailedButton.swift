//
//  PreviewDetailedButton.swift
//  Flags
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewDetailedButton: View {
    
    var image: String
    var text: String
    var action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var previewManager: PreviewManager
    
    var body: some View{
        if previewManager.isHovering {
            Button(action: {
                action()
            }, label: {
                HStack(spacing: 6){
                    Image(systemName: image)
                    Text(text)
                        .fontWeight(.medium)
                }
                .font(.title3)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.secondary)
                .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                .cornerRadius(64)
            }).buttonStyle(PlainButtonStyle())
        }else {
            Button(action: {
                action()
            }, label: {
                HStack(spacing: 6){
                    Image(systemName: image)
                    Text(text)
                        .fontWeight(.medium)
                }
                .font(.title3)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(BlurEffect(material: .toolTip, blendingMode: .withinWindow))
                .foregroundColor(.primary)
                .cornerRadius(64)
            }).buttonStyle(PlainButtonStyle())
        }
    }
}

struct PreviewDetailedButton_Previews: PreviewProvider {
    static var previews: some View {
        PreviewDetailedButton(image: "paintbrush.pointed.fill", text: "URL", action: { return })
    }
}
