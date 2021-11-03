//
//  ErrorPopupView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 02/11/2021.
//

import SwiftUI

struct ErrorPopupView: View {
    
    @EnvironmentObject var recording: RecordingStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16){
            HStack(alignment: .center, spacing: 8){
                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red).font(.title)
                Text("An unexpected error occured.").font(.headline)
            }
            
            Text("If the error persists, please contact us.")
            
            Button(action: {
                recording.state = .stopped
            }, label: {
                VStack{
                    Text("OK").padding(.vertical, 6)
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(4)
            })
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ErrorPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorPopupView()
    }
}
