//
//  TextEditView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/8.
//

import SwiftUI

struct TextEditView<PlaceHolder>: View where PlaceHolder: View {
    @Binding var text: String
    @FocusState var isFocused
    var placeHolder: () -> PlaceHolder


    var body: some View {
        #if os(iOS)
        if #available(iOS 16, *) {
            TextField(text: $text, axis: .vertical, label: placeHolder)
                .lineLimit(1...8)
        } else {
            TextField(text: $text, label: placeHolder)
                .submitLabel(.send)
        }
        #elseif os(macOS)
        TextField(text: $text, axis: .vertical, label: placeHolder)
            .lineLimit(1...8)
            .submitLabel(.return)
        #endif
    }
}

struct TextEditView_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        TextEditView(text: $text) {
            Text("Say something")
        }
        .frame(minHeight: 30)
        .background(Color.red)
    }
}
