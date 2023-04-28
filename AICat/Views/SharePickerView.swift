//
//  SharePicker.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/29.
//
import SwiftUI

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = { (_, _, _, _) in
            context.coordinator.didFinishSharing()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let base: ShareSheet

        init(_ base: ShareSheet) {
            self.base = base
        }

        func didFinishSharing() {
            // Handle completion if needed
        }
    }
}

#endif
