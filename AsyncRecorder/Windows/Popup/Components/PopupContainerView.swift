//
//  PopupContainerView.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 06/11/2021.
//

import SwiftUI

struct PopupContainerView<Content>: View where Content: View {
    @ViewBuilder var children: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16){
            children()
        }
    }
}

struct PopupContainerView_Previews: PreviewProvider {
    static var previews: some View {
        PopupContainerView{
            FinishedPopupView(url: "https://archie.com", videoID: "")
        }
    }
}
