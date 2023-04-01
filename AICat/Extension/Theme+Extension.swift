//
//  Theme+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/23.
//

import MarkdownUI
import SwiftUI

extension Theme {
    static let fancy = Theme()
        .text {
            ForegroundColor(.whiteText)
            FontSize(16)
        }
}

extension Color {
    static let background = Color("Background")
    static let primary = Color("Primary")
    static let blackText = Color("BlackText")
    static let whiteText = Color("WhiteText")
    static let aiBubbleBg = Color("AIBubbleBg")
}
