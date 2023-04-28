//
//  SystemUtil.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/6.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
typealias ImageType = UIImage
#elseif os(macOS)
typealias ImageType = NSImage
#endif

enum SystemUtil {
    static func copyToPasteboard(content: String) -> Bool {
        #if os(iOS)
        UIPasteboard.general.string = content
        return true
        #elseif os(macOS)
        let p = NSPasteboard.general
        p.declareTypes([.string], owner: nil)
        return p.setString(content, forType: .string)
        #endif
    }

    static var maybeFromTestFlight: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.absoluteString.lowercased().contains("sandbox")
    }

    static func exportToMarkDown(messages: [ChatMessage], fileUrl: URL) -> Bool {
        guard let content = messagesToMDContent(messages: messages) else { return false }
        do {
            try content.write(to: fileUrl)
            return true
        } catch {
            print("saveFailed: \(error)")
            return false
        }
    }

    
    static func saveMessageAsMD(messages: [ChatMessage], title: String) -> URL? {
        guard let content = messagesToMDContent(messages: messages) else { return nil }
        guard let downloadsFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("无法获取Downloads文件夹路径")
            return nil
        }

        let fileName = "\(title).md"

        let fileURL = downloadsFolderURL.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL)
            return fileURL
        } catch {
            print("保存文件错误: \(error)")
            return nil
        }
    }

    static func messagesToMDContent(messages: [ChatMessage]) -> Data? {
        let content = messages.map { "**[\($0.role)]:** \($0.content)" }.joined(separator: "\n\n")
        return content.data(using: .utf8)
    }
}
