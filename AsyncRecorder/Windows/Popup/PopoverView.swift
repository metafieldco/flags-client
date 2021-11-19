//
//  PopoverView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 17/11/2021.
//

import SwiftUI

struct Section<Content>: View where Content: View {
    @ViewBuilder var children: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6){
            children()
        }
    }
}

struct Devices: View {
    
    @State var selected = "No device"
    var devices: [String]
    
    var body: some View {
        List{
            ForEach(devices, id: \.self){ device in
                Device(name: device, selected: $selected)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
}

struct Device: View {
    var name: String
    
    @Binding var selected: String
    @State var hovering = false
    
    var body: some View {
        Button(action: {
            withAnimation(Animation.easeInOut(duration: 0.05)){
                selected = name
            }
        }, label: {
            HStack{
                Image(systemName: "checkmark")
                    .font(.footnote)
                    .opacity(selected == name ? 1 : 0)
                Text(name)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(hovering ? Color.primary.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

struct ActionButton: View {
    var image: String?
    var name: String
    var action: ()->Void
    
    @State var hovering = false
    
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
            .background(hovering ? Color.primary.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

struct PopoverDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 16).padding(.vertical, 8)
    }
}

struct PopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            
            Section{
                ActionButton(image: "video", name: "Start recording", action: {
                    print("starting recording ...")
                })
            }
            
            PopoverDivider()
            
            Section{
                Text("Camera")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                Devices(devices: ["No device", "FaceTime HD Camera (Built-in)", "Reincubate Camo"])
            }
            
            PopoverDivider()
            
            Section{
                Text("Microphone")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                Devices(devices: ["No device", "Built-in Microphone", "Archie's Airpods", "Reincubate Camo"])
            }
                
            PopoverDivider()
            
            Section{
                ActionButton(name: "Quit AsyncRecorder", action: {
                    print("quitting ...")
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
