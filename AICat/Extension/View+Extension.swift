//
//  View+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/22.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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

    func snapshot() async -> ImageType {
        #if os(iOS)
        return await MainActor.run {
            let controller = UIHostingController(rootView: self)
            let view = controller.view
            let targetSize = controller.view.intrinsicContentSize
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: targetSize)

            return renderer.image { _ in
                view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
        #elseif os(macOS)
        return await ImageRenderer(contentWithScreenScale: self.environment(\.colorScheme, .dark)).nsImage ?? NSImage()
        #endif
    }
}
