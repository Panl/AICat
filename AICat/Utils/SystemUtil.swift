//
//  SystemUtil.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/6.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum SystemUtil {
    static func copyToPasteboard(content: String) {
        #if os(iOS)
        UIPasteboard.general.string = content
        #elseif os(macOS)
        NSPasteboard.general.setString(content, forType: .string)
        #endif
    }

    static var maybeFromTestFlight: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.absoluteString.lowercased().contains("sandbox")
    }

    static func shareImage(_ image: UIImage) {
        #if os(iOS)
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
        #endif
    }
}

enum HapticEngine {

    static func trigger() {
        #if os(iOS)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        #endif
    }
}
