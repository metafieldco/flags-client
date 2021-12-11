//
//  CountdownView.swift
//  Flags
//
//  Created by Archie Edwards on 07/11/2021.
//

import SwiftUI

struct CountdownView: View {
    
    @EnvironmentObject var timer: RecordingManager
    
    var body: some View {
        HStack{
            Spacer()
            VStack{
                Spacer()
                ZStack{
                    Circle()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.black)
                    Text("\(timer.countdown)")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .zIndex(1)
                }
                Spacer()
            }
            Spacer()
        }
        .background(Color.black.opacity(0.5))
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView()
    }
}
