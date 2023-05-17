//
//  MessageView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/21.
//

import SwiftUI
import MarkdownUI

typealias DeleteFunction = () -> Void
typealias CopyFunction = () -> Void
typealias ShareFunction = () -> Void
typealias ClickFunction = () -> Void

struct MineMessageView: View {
    let message: ChatMessage
    var onDelete: DeleteFunction?
    var onCopy: CopyFunction?
    var onShare: ShareFunction?
    var showActions = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer(minLength: 40)
                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .textSelection(.enabled)
                    .font(.manrope(size: 16, weight: .regular))
                    .foregroundColor(.whiteText)
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .frame(minWidth: 64, minHeight: 40)
                    .background(
                        LinearGradient(
                            colors: [.primaryColor, .primaryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .clipShape(CornerRadiusShape(radius: 4, corners: .topRight))
                    .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topLeft]))
                    .padding(.trailing, 16)
            }
            if showActions {
                HStack {
                    Spacer()
                    Button(action: { onCopy?() }) {
                        Image(systemName: "doc.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.borderless)
                    Button(action: { onDelete?() }) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.borderless)
//                    Button(action: { onShare?() }) {
//                        Image(systemName: "arrowshape.turn.up.right.circle.fill")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                    }
                }
                .padding(.horizontal, 30)
                .tint(.primaryColor.opacity(0.6))
            }
        }
    }
}

struct AICatMessageView: View {
    let message: ChatMessage
    var onDelete: DeleteFunction?
    var onCopy: CopyFunction?
    var onShare: ShareFunction?
    var showActions = false

    var body: some View {
        if message.content.isEmpty {
            InputingMessageView()
        } else if containsCodeBlock(content: message.content) {
            VStack(alignment: .leading, spacing: 0) {
                Markdown(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                   .textSelection(.enabled)
                   .markdownCodeSyntaxHighlighter(.splash(theme: .sundellsColors(withFont: .init(size: Theme.fontSize))))
                   .markdownTheme(.gitHub.text { FontSize(Theme.fontSize) })
                   .padding(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
                if showActions {
                    actionsView
                        .padding(.horizontal, 20)
                        .tint(.primaryColor.opacity(0.6))
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .textSelection(.enabled)
                    .font(.manrope(size: 16, weight: .regular))
                    .foregroundColor(.blackText)
                    .padding(EdgeInsets.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .frame(minWidth: 64, minHeight: 40)
                    .background(Color.aiBubbleBg)
                    .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
                    .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
                    .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 36))
                if showActions {
                    actionsView
                        .padding(.horizontal, 30)
                        .tint(.primaryColor.opacity(0.6))
                }
            }
        }
    }

    var actionsView: some View {
        HStack {
            Button(action: { onCopy?() }) {
                Image(systemName: "doc.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
            Button(action: { onDelete?() }) {
                Image(systemName: "trash.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
            Button(action: { onShare?() }) {
                Image(systemName: "arrowshape.turn.up.right.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
        }
    }

    func containsCodeBlock(content: String) -> Bool {
        return content.contains("```")
    }
}

struct NewSessionMessageView: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 0.5)
                .fill(
                    LinearGradient(colors: [.clear, .primaryColor.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 1)
            Text("NEW SESSION")
            RoundedRectangle(cornerRadius: 0.5)
                .fill(
                    LinearGradient(colors: [.clear, .primaryColor.opacity(0.4)], startPoint: .trailing, endPoint: .leading)
                )
                .frame(height: 1)
        }
        .font(.manrope(size: 10, weight: .regular))
        .opacity(0.6)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

struct MessageView: View {
    let message: ChatMessage
    var onDelete: DeleteFunction?
    var onCopy: CopyFunction?
    var onShare: ShareFunction?
    var showActions: Bool = false
    var body: some View {
        if message.isNewSession {
            NewSessionMessageView()
        } else if message.isFromUser {
            MineMessageView(message: message, onDelete: onDelete, onCopy: onCopy, onShare: onShare, showActions: showActions)
        } else {
            AICatMessageView(message: message, onDelete: onDelete, onCopy: onCopy, onShare: onShare, showActions: showActions)
        }
    }
}

struct RectCorner: OptionSet {

    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)

    static let allCorners: RectCorner = [.topLeft, topRight, .bottomLeft, .bottomRight]
}


// draws shape with specified rounded corners applying corner radius
struct CornerRadiusShape: Shape {

    var radius: CGFloat = .zero
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let p1 = CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius  : rect.minY )
        let p2 = CGPoint(x: corners.contains(.topLeft) ? rect.minX + radius : rect.minX, y: rect.minY )

        let p3 = CGPoint(x: corners.contains(.topRight) ? rect.maxX - radius : rect.maxX, y: rect.minY )
        let p4 = CGPoint(x: rect.maxX, y: corners.contains(.topRight) ? rect.minY + radius  : rect.minY )

        let p5 = CGPoint(x: rect.maxX, y: corners.contains(.bottomRight) ? rect.maxY - radius : rect.maxY )
        let p6 = CGPoint(x: corners.contains(.bottomRight) ? rect.maxX - radius : rect.maxX, y: rect.maxY )

        let p7 = CGPoint(x: corners.contains(.bottomLeft) ? rect.minX + radius : rect.minX, y: rect.maxY )
        let p8 = CGPoint(x: rect.minX, y: corners.contains(.bottomLeft) ? rect.maxY - radius : rect.maxY )


        path.move(to: p1)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: p2,
                    radius: radius)
        path.addLine(to: p3)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: p4,
                    radius: radius)
        path.addLine(to: p5)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: p6,
                    radius: radius)
        path.addLine(to: p7)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: p8,
                    radius: radius)
        path.closeSubpath()

        return path
    }
}

struct ErrorMessageView: View {
    let errorMessage: String
    let retry: () -> Void
    let clear: () -> Void
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
                                    colors: [Color.primaryColor, Color.primaryColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(Color.primaryColor)
                    }
                }
                .buttonStyle(.borderless)
                Button(
                    action: clear
                ) {
                    if #available(iOS 16.0, *) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(
                                LinearGradient(
                                    colors: [.primaryColor, .primaryColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .tint(.primaryColor)
                    }
                }
                .buttonStyle(.borderless)
            }.padding(.horizontal, 16)
        }
    }
}

struct InputingMessageView: View {
    @State private var shouldAnimate = false

    let circleSize: CGFloat = 6

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.primaryColor.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: shouldAnimate)
            Circle()
                .fill(Color.primaryColor.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.3), value: shouldAnimate)
            Circle()
                .fill(Color.primaryColor.opacity(0.8))
                .frame(width: circleSize, height: circleSize)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.6), value: shouldAnimate)
        }
        .padding(EdgeInsets.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        .frame(height: 40)
        .background(Color.aiBubbleBg)
        .clipShape(CornerRadiusShape(radius: 4, corners: .topLeft))
        .clipShape(CornerRadiusShape(radius: 20, corners: [.bottomLeft, .bottomRight, .topRight]))
        .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 36))
        .onAppear {
            self.shouldAnimate.toggle()
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            AICatMessageView(message: ChatMessage(role: "user", content: "you are beautiful", conversationId: ""), showActions: true)
            MineMessageView(message: ChatMessage(role: "", content: "### title ```swift```", conversationId: ""), showActions: true)
            ErrorMessageView(errorMessage: "RequestTime out", retry: {}, clear: {})
            NewSessionMessageView()
            Spacer()
        }
        .background()
        .environment(\.colorScheme, .light)

    }
}

