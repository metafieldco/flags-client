//
//  PopoverView.swift
//  Flags
//
//  Created by Archie Edwards on 17/11/2021.
//

import SwiftUI
import AVFoundation

struct Section<Content>: View where Content: View {
    @ViewBuilder var children: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6){
            children()
        }
    }
}

struct Devices: View {
    
    @Binding var hovering: String
    @Binding var selected: CaptureDevice
    @Binding var devices: [CaptureDevice]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            ForEach(devices, id: \.uniqueID){ device in
                Device(device: device, selected: $selected, hovering: $hovering)
            }
        }
    }
}


struct Device: View {
    var device: CaptureDevice
    
    @Binding var selected: CaptureDevice
    @Binding var hovering: String
    
    var body: some View {
        Button(action: {
            if selected != device {
                withAnimation(Animation.easeInOut(duration: 0.05)){
                    selected = device
                }
            }
        }, label: {
            HStack{
                Image(systemName: "checkmark")
                    .font(.footnote)
                    .opacity(selected == device ? 1 : 0)
                Text(device.localizedName)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(hovering == device.uniqueID ? Color.primary.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .onHover { hovering in
            if hovering {
                self.hovering = device.uniqueID
            } else if self.hovering == device.uniqueID {
                self.hovering = ""
            }
        }
    }
}

struct ActionButton: View {
    @Binding var hovering: String
    
    var image: String?
    var name: String
    var action: ()->Void
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack{
                if image != nil {
                    Image(systemName: image!)
                }
                Text(name)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(hovering == name ? Color.primary.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .onHover { hovering in
            if hovering {
                self.hovering = name
            } else if self.hovering == name {
                self.hovering = ""
            }
        }
    }
}

struct PopoverDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 16).padding(.vertical, 8)
    }
}

struct PopoverView: View {
    
    @EnvironmentObject var recordingManager: RecordingManager
    @EnvironmentObject var camManager: CamManager
    @EnvironmentObject var micManager: MicManager
    
    @State var hovering = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            
            Section{
                ActionButton(hovering: $hovering, image: "video", name: "Start recording", action: {
                    recordingManager.start()
                })
            }
            
            PopoverDivider()
            
            Section{
                Text("Camera")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                Devices(hovering: $hovering, selected: $camManager.device, devices: $camManager.devices)
            }
            
            PopoverDivider()
            
            Section{
                Text("Microphone")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                Devices(hovering: $hovering, selected: $micManager.device, devices: $micManager.devices)
            }
                
            PopoverDivider()
            
            Section{
                ActionButton(hovering: $hovering, name: "Quit Flags", action: {
                    NSRunningApplication.current.terminate()
                })
            }
        }
        .padding(.vertical)
        .frame(width: 250)
    }
}

struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverView()
    }
}
