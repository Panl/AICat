//
//  ToastModifier.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/15.
//

import SwiftUI

struct Toast<Content: View>: ViewModifier {
    @Binding var isShowing: Bool
    let toastContent: () -> Content

    func body(content: _ViewModifier_Content<Self>) -> some View {
        ZStack {
            content
            if isShowing {
                toastContent()
                    .transition(AnyTransition.opacity.animation(.easeInOut))
            }
        }
    }
}

extension View {
    func toast<Content: View>(isShowing: Binding<Bool>, content: @escaping () -> Content) -> some View {
        self.modifier(Toast(isShowing: isShowing, toastContent: content))
    }
}

