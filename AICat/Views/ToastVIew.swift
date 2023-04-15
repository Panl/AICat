//
//  ToastView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/15.
//

import SwiftUI

struct Toast: Equatable {
    var type: ToastStyle
    var message: String
    var duration: Double = 3
}

enum ToastStyle {
    case error
    case warning
    case success
    case info
}

extension ToastStyle {
    var themeColor: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .info: return Color.blue
        case .success: return Color.green
        }
    }

    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct ToastView: View {
    var toast: Toast

    var body: some View {
        HStack {
            Image(systemName: toast.type.iconFileName)
                .foregroundColor(toast.type.themeColor)
            Text(toast.message)
                .foregroundColor(.whiteText)
                .font(.manrope(size: 14, weight: .medium))
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(.primary.opacity(0.8))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                Spacer()
            }
            Spacer()
            ToastView(toast: Toast(type: .success, message: "Already Premium"))
            ToastView(toast: Toast(type: .error, message: "Already Premium"))
            ToastView(toast: Toast(type: .info, message: "Already Premium"))
            ToastView(toast: Toast(type: .warning, message: "Already Premium"))
            Spacer()
        }
        .background()
        .environment(\.colorScheme, .light)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: 24)
                }.animation(.spring(), value: toast)
            )
            .onChange(of: toast) { value in
                showToast()
            }
    }

    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            VStack {
                ToastView(toast: toast)
                Spacer()
            }
            .transition(.move(edge: .top))
        }
    }

    private func showToast() {
        guard let toast = toast else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if toast.duration > 0 {
            workItem?.cancel()

            let task = DispatchWorkItem {
               dismissToast()
            }

            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }

        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

