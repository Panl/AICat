//
//  DocumentPicker.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/29.
//

#if os(iOS)
import Foundation
import UIKit

class DocumentPicker: NSObject {

    static let shared = DocumentPicker()

    private override init() {}

    func export(file: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [file])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .automatic
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
        }
    }

}

extension DocumentPicker: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {}
}

#endif

