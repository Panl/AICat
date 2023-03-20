//
//  Database+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/20.
//

import Blackbird

extension Blackbird.Database {

    func upsert(model: some BlackbirdModel) async {
        do {
            try await model.write(to: self)
        } catch {
            debugPrint(error)
        }
    }
}
