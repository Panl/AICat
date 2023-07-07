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

    static func custom() -> MarkdownUI.Theme {
        .gitHub.text {
            ForegroundColor(.primary)
            BackgroundColor(Color.clear)
            FontSize(fontSize)
            FontFamily(.custom("Manrope"))
            FontWeight(.regular)
        }
        .codeBlock { configuration in
          ScrollView(.horizontal) {
            configuration.label
                  .relativeLineSpacing(.em(0.1))
              .markdownTextStyle {
                FontFamilyVariant(.monospaced)
                FontFamily(.custom("Manrope"))
                FontSize(fontSize)
              }
              .padding(16)
              .padding(.top, 20)
          }
          .overlay(alignment: .top) {
              HStack(alignment: .center) {
                  Text((configuration.language ?? "code").uppercased())
                      .foregroundStyle(.tertiary)
                      .font(.callout)
                      .lineLimit(1)
                  Spacer()
                  CopyButton {
                      SystemUtil.copyToPasteboard(content: configuration.content)
                  }
              }
              .padding(.leading, 16)
              .padding(.trailing, 12)
              .padding(.top, 12)
          }
          .background(Color.secondary.opacity(0.05))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .markdownMargin(top: 0, bottom: 16)
        }
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

struct CopyButton: View {
    var copy: () -> Void
    @State var isCopied = false
    var body: some View {
        Button(action: {
            withAnimation(.linear(duration: 0.1)) {
                isCopied = true
            }
            copy()
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.linear(duration: 0.1)) {
                    isCopied = false
                }
            }
        }) {
            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 4, style: .circular)
                )
        }
        .buttonStyle(.borderless)
    }
}
