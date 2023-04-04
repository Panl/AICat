//
//  View+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/22.
//

import SwiftUI

extension View {

    func endEditing(force: Bool) {
        #if os(iOS)
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.forEach { $0.endEditing(true) }
        #endif
    }

    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
