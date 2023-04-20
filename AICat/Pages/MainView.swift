//
//  MainView.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/24.
//

import SwiftUI
import Blackbird

struct MainView: View {
    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 560 {
                SplitView(size: proxy.size)
            } else {
                CompactView()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
