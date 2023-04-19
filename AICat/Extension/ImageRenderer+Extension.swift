//
//  ImageRenderer+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/20.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public extension ImageRenderer {

    @MainActor
    convenience init(content: Content, scale: CGFloat) {
        self.init(content: content)
        self.scale = scale
    }

    #if os(iOS) || os(macOS) || os(tvOS)
    @MainActor
    convenience init(contentWithScreenScale content: Content) {
        #if os(iOS) || os(tvOS)
        let scale = UIScreen.main.scale
        #elseif os(macOS)
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        #endif

        self.init(content: content, scale: scale)
    }
    #endif
}
