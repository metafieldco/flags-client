//
//  PreviewFeedbackView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import SwiftUI

struct PreviewFeedbackView: View {
    
    var msg: String
    
    var body: some View {
        VStack(spacing: 6){
            Spacer()
            Image(systemName: "checkmark")
            Text(msg)
                .fontWeight(.medium)
            Spacer()
        }
        .font(.title3)
    }
}

struct PreviewFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewFeedbackView(msg: "Copied link")
    }
}
