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
}
