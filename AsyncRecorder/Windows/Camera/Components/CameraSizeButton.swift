//
//  CameraSizeButton.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import SwiftUI

struct CameraSizeButton: View {
    var size: CameraSize
    
    @EnvironmentObject var camManager: CamManager
    @State private var foregroundColor: Color = .secondary
    
    var body: some View {
        Button(action: {
            camManager.size = size
        }, label: {
            Image(systemName: size.buttonDetails.systemName)
                .font(size.buttonDetails.font)
                .foregroundColor(camManager.size == size ? .primary : foregroundColor)
                .onHover{ hovering in
                    if hovering {
                        foregroundColor = .primary
                    }else{
                        foregroundColor = .secondary
                    }
                }
        }).buttonStyle(PlainButtonStyle())
    }
}

struct CameraSizeButton_Previews: PreviewProvider {
    static var previews: some View {
        CameraSizeButton(size: .large)
    }
}
