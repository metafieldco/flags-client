//
//  ErrorView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 16/11/2021.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 12){
                HStack(spacing: 8){
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red).font(.title2)
                    Text("An unexpected error occured.").font(.headline)
                    Spacer()
                }
                
                Text("If the error persists, please contact us.")
            }
            Spacer()
        }
        .padding()
        .background(
            BlurEffect(material: .fullScreenUI, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
