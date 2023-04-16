//
//  LoadingIndocator.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/4.
//

import SwiftUI

struct LoadingIndocator: View {

    @State private var isLoading = false
    var themeColor = Color.primaryColor

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let borderWidth = 0.15 * size
            let drawSize = size - borderWidth
            ZStack {
                Color.clear
                Circle()
                    .stroke(themeColor.opacity(0.3), lineWidth: borderWidth)
                    .frame(width: drawSize, height: drawSize)
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 0.15 * size, lineCap: .round))
                    .frame(width: drawSize, height: drawSize)
                    .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                    .animation(.linear(duration: 0.6).repeatForever(autoreverses: false), value: isLoading)
                    .onAppear() {
                        isLoading.toggle()
                    }
            }
        }
    }
}

struct LoadingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIndocator(themeColor: .white)
            .frame(width: 24, height: 24)
            .background()
            .environment(\.colorScheme, .dark)
    }
}
