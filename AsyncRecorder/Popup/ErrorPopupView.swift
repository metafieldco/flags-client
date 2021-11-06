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
        PopupContainerView{
            HStack(alignment: .center, spacing: 8){
                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red).font(.title)
                Text("An unexpected error occured.").font(.headline)
            }
            
            Text("If the error persists, please contact us.")
            
            ButtonView(text: "OK", color: .gray){
                recording.state = .stopped
            }
        }
    }
}

struct ErrorPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorPopupView()
    }
}
