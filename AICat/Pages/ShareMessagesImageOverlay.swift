//
//  ShareMessagesImageOverlay.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/16.
//

import SwiftUI

struct ShareMessagesImageOverlay: View {

    let shareMessageSnapshot: ImageType?
    let onClose: () -> Void
    let onSave: (ImageType) -> Void

    var body: some View {
        ZStack {
            if let shareMessageSnapshot {
                Color.black.opacity(0.816)
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture()
                    )
                VStack(spacing: 0) {
                    #if os(iOS)
                    Image(uiImage: shareMessageSnapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(16)
                    #elseif os(macOS)
                    Image(nsImage: shareMessagesSnapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 560)
                        .padding(16)
                    #endif
                    HStack(spacing: 20) {
                        Button(action: {
                            onClose()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.borderless)
                        Button(
                            action: {
                                onSave(shareMessageSnapshot)
                            }
                        ) {
                            Image(systemName: "arrow.down.to.line.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        Button(action: {
                            SystemUtil.shareImage(shareMessageSnapshot)
                        }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.borderless)
                        #endif
                    }
                    .padding(.bottom, 16)
                    .tint(.white)
                }
            }
        }
    }
}

struct ShareMessagesImageOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ShareMessagesImageOverlay(shareMessageSnapshot: nil, onClose: {}, onSave: { _ in })
    }
}
