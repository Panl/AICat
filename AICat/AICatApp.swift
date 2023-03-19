//
//  AICatApp.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//

import SwiftUI
import Blackbird

let dbPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/db.sqlite"

@main
struct AICatApp: App {

    var database = try! Blackbird.Database(path: dbPath, options: .debugPrintEveryQuery)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.blackbirdDatabase, database)
        }
    }
}
