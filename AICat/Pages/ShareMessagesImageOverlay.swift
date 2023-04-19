//
//  ShareMessagesImageOverlay.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/16.
//

import SwiftUI

struct ShareMessagesImageOverlay: View {
    @EnvironmentObject var appStateVM: AICatStateViewModel

    var body: some View {
        ZStack {
            if let shareMessagesSnapshot = appStateVM.shareMessagesSnapshot {
                Color.black.opacity(0.816)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    #if os(iOS)
                    Image(uiImage: shareMessagesSnapshot)
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
                            appStateVM.shareMessagesSnapshot = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.borderless)
                        Button(
                            action: {
                                appStateVM.saveImageToAlbum(image: shareMessagesSnapshot)
                            }
                        ) {
                            Image(systemName: "arrow.down.to.line.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        Button(action: {
                            SystemUtil.shareImage(shareMessagesSnapshot)
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
        ShareMessagesImageOverlay()
            .environmentObject(AICatStateViewModel())
    }
}
