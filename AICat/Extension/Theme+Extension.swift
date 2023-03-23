//
//  Theme+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/23.
//

import MarkdownUI

extension Theme {
    static let fancy = Theme()
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
        }
        .link {
            ForegroundColor(.purple)
        }
        .paragraph { label in
            label
                .relativeLineSpacing(.em(0.25))
                .markdownMargin(top: 0, bottom: 16)
        }
        .listItem { label in
            label.markdownMargin(top: .em(0.25))
        }
}
