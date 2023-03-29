//
//  Bundle+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/30.
//

import Foundation

extension Bundle {
    var releaseVersion: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}
