import MarkdownUI
import SwiftUI

struct ChatCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    let brightMode: Bool
    let fontSize: Double

    init(brightMode: Bool, fontSize: Double) {
        self.brightMode = brightMode
        self.fontSize = fontSize
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        let content = highlightedCodeBlock(
            code: content,
            language: language ?? "",
            brightMode: brightMode,
            fontSize: fontSize
        )
        return Text(AttributedString(content))
    }
}

