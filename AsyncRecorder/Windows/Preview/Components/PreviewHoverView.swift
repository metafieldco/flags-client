//
//  PreviewHoverView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewHoverView: View {
    var body: some View {
        HStack{
            Spacer()
            VStack{
                Spacer()
            }
            Spacer()
        }
        .background(
            BlurEffect(material: .fullScreenUI, blendingMode: .withinWindow)
        )
    }
}

struct PreviewHoverView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewHoverView()
    }
}
