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

#if os(iOS)
typealias ImageType = UIImage
#elseif os(macOS)
typealias ImageType = NSImage
#endif

enum SystemUtil {
    static func copyToPasteboard(content: String) -> Bool {
        #if os(iOS)
        UIPasteboard.general.string = content
        return true
        #elseif os(macOS)
        let p = NSPasteboard.general
        p.declareTypes([.string], owner: nil)
        return p.setString(content, forType: .string)
        #endif
    }

    static var maybeFromTestFlight: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.absoluteString.lowercased().contains("sandbox")
    }

    static func shareImage(_ image: ImageType) {
        #if os(iOS)
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
        #elseif os(macOS)
        //TODO: show NSSharingServicePicker
        #endif
    }
}
