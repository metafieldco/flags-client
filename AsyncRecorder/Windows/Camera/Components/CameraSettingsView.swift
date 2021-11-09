//
//  CameraSettingsView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import SwiftUI

struct CameraSettingsView: View {
    
    @EnvironmentObject var camManager: CamManager
    
    var body: some View {
        HStack{
            HStack(spacing: 16){
                ForEach(CameraSize.allCases, id: \.self) { value in
                    CameraSizeButton(size: value)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .background(BlurEffect(material: .toolTip, blendingMode: .withinWindow))
        .cornerRadius(8)
        .padding(.bottom, camManager.size == .fullScreen ? 48 : 12)
    }
}

struct CameraSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CameraSettingsView()
    }
}
