//
//  DeviceToggle.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 05/11/2021.
//

import SwiftUI

struct DeviceToggle: View {
    
    @Binding var enabled: Bool
    var device: String
    
    var body: some View {
        Toggle(isOn: $enabled, label: {
            Text(device)
            Spacer()
        })
            .frame(maxWidth: .infinity)
            .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
}

struct DeviceToggle_Previews: PreviewProvider {
    static var previews: some View {
        DeviceToggle(enabled: .constant(true), device: "Camera")
    }
}
