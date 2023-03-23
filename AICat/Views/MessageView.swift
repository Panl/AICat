//
//  MessageView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/21.
//

import SwiftUI
import MarkdownUI

struct MineMessageView: View {
    let message: ChatMessage
    var body: some View {
        ZStack {
            HStack {
                Spacer(minLength: 40)
                Text(message.content)
                    .textSelection(.enabled)
                    .font(.manrope(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.8), .black.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .clipShape(CornerRadiusShape(radius: 4, corners: .topRight))
                    .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topLeft]))
                    .padding(.trailing, 20)
            }
        }
    }
}

struct AICatMessageView: View {
    let message: ChatMessage
    var body: some View {
        if containsCodeBlock(content: message.content) {
            Markdown(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
               .textSelection(.enabled)
               .markdownCodeSyntaxHighlighter(.splash(theme: .sundellsColors(withFont: .init(size: 16))))
               .markdownTheme(.gitHub)
               .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        } else {
            Text(LocalizedStringKey(message.content.trimmingCharacters(in: .whitespacesAndNewlines)))
                .font(.manrope(size: 16, weight: .medium))
                .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(Color(red: 0.97, green: 0.97, blue: 0.98))
                .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
                .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
                .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 36))

        }
    }

    func containsCodeBlock(content: String) -> Bool {
        let regextPattern = "```[\\w\\W]*?```"
        if let regex = try? NSRegularExpression(pattern: regextPattern) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            return !matches.isEmpty
        }
        return false
    }
}

struct MessageView: View {
    let message: ChatMessage
    var body: some View {
        if message.role == "user" {
            MineMessageView(message: message)
        } else {
            AICatMessageView(message: message)
        }
    }
}

struct CornerRadiusShape: Shape {
    var radius = CGFloat.infinity
    var corners = UIRectCorner.allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ErrorMessageView: View {
    let errorMessage: String
    let retry: () -> Void
    var body: some View {
        ZStack {
            HStack {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .font(.manrope(size: 16, weight: .medium))
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Button(
                    action: retry
                ) {
                    if #available(iOS 16.0, *) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(
                                LinearGradient(
                                    colors: [.black.opacity(0.9), .black.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(.black.opacity(0.8))
                    }
                }
            }.padding(.horizontal, 20)
        }
    }
}

struct InputingMessageView: View {
    @State private var shouldAnimate = false

    let circleSize: CGFloat = 6

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.black.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: shouldAnimate)
            Circle()
                .fill(Color.black.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.3), value: shouldAnimate)
            Circle()
                .fill(Color.black.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.6), value: shouldAnimate)
        }
        .padding(EdgeInsets.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        .frame(height: 40)
        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
        .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
        .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
        .padding(.init(top: 0, leading: 20, bottom: 0, trailing: 36))
        .onAppear {
            self.shouldAnimate.toggle()
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        AICatMessageView(message: ChatMessage(role: "user", content: "you are beautiful", conversationId: ""))
    }
}

