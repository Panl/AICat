//
//  LoadingIndocator.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/4.
//

import SwiftUI

struct LoadingIndocator: View {

    @State private var isLoading = false

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let borderWidth = 0.15 * size
            let drawSize = size - borderWidth
            ZStack {
                Color.clear
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: borderWidth)
                    .frame(width: drawSize, height: drawSize)
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(.primary, style: StrokeStyle(lineWidth: 0.08 * size, lineCap: .round))
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
        LoadingIndocator()
            .frame(width: 24, height: 24)
            .environment(\.colorScheme, .dark)
    }
}
