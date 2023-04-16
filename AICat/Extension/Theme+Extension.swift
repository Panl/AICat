//
//  Theme+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/23.
//

import MarkdownUI
import SwiftUI

extension Theme {
    static var fontSize: Double {
        #if os(macOS)
        return 14
        #else
        return 16
        #endif
    }

    static let fancy = Theme()
        .text {
            ForegroundColor(.whiteText)
            FontSize(fontSize)
        }

    static let aiMessage = Theme()
        .text {
            ForegroundColor(.blackText)
            FontSize(fontSize)
        }
}

extension Color {
    static let background = Color("Background")
    static let primaryColor = Color("Primary")
    static let blackText = Color("BlackText")
    static let whiteText = Color("WhiteText")
    static let aiBubbleBg = Color("AIBubbleBg")
    static let thumb = Color("Thumb")
}
