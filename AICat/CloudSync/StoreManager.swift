//
//  StoreManager.swift
//  AICat
//
//  Created by Lei Pan on 2023/5/16.
//

import Foundation
import CloudKit
import Blackbird
import Combine

let DataStore = StoreManager()

class StoreManager {

    let receiveDataFromiCloud = PassthroughSubject<Void, Never>()

    private let cloudKitService = CloudKitService()

    var iCloudServiceAvailable: Bool {
        get async {
            await cloudKitService.isAccountAvailable
        }
    }

    private func prepare() async throws {
        try await cloudKitService.register()
    }

    func save(_ obj: any PushableObject) async {
        await db.upsert(item: obj)
        await pushAfterSave()
    }

    func save(items: [any PushableObject]) async {
        for item in items {
            await db.upsert(item: item)
        }
        await pushAfterSave()
    }

    private func pushAfterSave() async {
        do {
            try await pushChangesAndDeleteInDB()
        } catch {
            debugPrint(error)
        }
    }

    private func pushChangesAndDeleteInDB() async throws {
        let pushItems = await db.queryPushItems()
        guard pushItems.isNotEmpty else { return }
        _ = try await cloudKitService.pushChanges(items: pushItems)
        await db.delete(items: pushItems)
        debugPrint("CloudKit pushItems pushed, count: \(pushItems.count)")
    }

    private func pullChangesAndSaveToDB() async throws {
        let (records, token, moreComing) = try await cloudKitService.pullChanges()
        await db.save(records: records)
        UserDefaults.save(serverChangeToken: token)
        debugPrint("CloudKit Changes pulled, count: \(records.count)")
        if moreComing {
            try await pullChangesAndSaveToDB()
        }
    }

    func sync(complete: ((CKError?) -> Void)?) {
        Task { @MainActor in
            do {
                try await sync()
                complete?(nil)
            } catch {
                complete?(error as? CKError)
                debugPrint("CloudKit push failed: \(error.localizedDescription)")
            }
        }
    }

    private func sync() async throws {
        try await prepare()
        if UserDefaults.serverChangeToken() == nil {
            try await pushAllRecords()
        }
        try await pullChangesAndSaveToDB()
        try await pushChangesAndDeleteInDB()
        receiveDataFromiCloud.send(())
    }

    private func pushAllRecords() async throws {
        let allPushItems = await db.allPushableToPushItems()
        guard allPushItems.isNotEmpty else { return }
        let pushedItems = try await cloudKitService.pushChanges(items: allPushItems)
        debugPrint("CloudKit All Records Pushed, count: \(pushedItems.count)")
    }
}
