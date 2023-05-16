//
//  CloudKitService.swift
//  AICat
//
//  Created by Lei Pan on 2023/5/15.
//

import CloudKit
import AppCenterCrashes
import Blackbird
import SwiftUI

extension Array {

    func join(separator: Element) -> [Element] {
        return (0 ..< 2 * count - 1).map { $0 % 2 == 0 ? self[$0/2] : separator }
    }

    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    var isNotEmpty: Bool {
        !isEmpty
    }
}

final class CloudKitService {

    private let container: CKContainer
    private let privateDB: CKDatabase
    private let zoneID: CKRecordZone.ID
    private let privateSubscriptionId = "private-changes"
    private let zoneName = "AICatZone"

    @AppStorage("AICAT_ZONE_CREATED") var zoneCreated: Bool = false
    @AppStorage("SUBSCRIPTION_CREATED") var subscriptionCreated: Bool = false

    init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    func register() async throws {
        try await createAICatZoneIfNeeded()
        await subscribeChanges()
    }

    func createAICatZoneIfNeeded() async throws {
        guard !zoneCreated else { return }
        do {
            try await privateDB.recordZone(for: zoneID)
            zoneCreated = true
        } catch {
            if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                let customZone = CKRecordZone(zoneID: zoneID)
                try await privateDB.save(customZone)
                zoneCreated = true
            } else {
                throw error
            }
        }
    }

    var isAccountAvailable: Bool {
      get async {
        do {
          return try await checkAccountStatus() == .available
        } catch {
          return false
        }
      }
    }

    func subscribeChanges() async {
        guard !subscriptionCreated else { return }
        do {
            _ = try await subscription(for: privateSubscriptionId)
            subscriptionCreated = true
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                let subscription = CKDatabaseSubscription(subscriptionID: privateSubscriptionId)
                let notiInfo = CKSubscription.NotificationInfo()
                notiInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notiInfo
                do {
                    _ = try await privateDB.save(subscription)
                    subscriptionCreated = true
                } catch {
                    debugPrint("--save subscription failed: \(error)")
                }
            } else {
                debugPrint("--fetach subscription failed: \(error)")
            }
        }
    }

    func subscription(for id: CKSubscription.ID) async throws -> CKSubscription? {
        return try await withCheckedThrowingContinuation { continuation -> Void in
            privateDB.fetch(withSubscriptionID: id) { subscription, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: subscription)
                }
            }
        }
    }

    func checkAccountStatus() async throws -> CKAccountStatus {
        try await CKContainer.default().accountStatus()
    }

    func pushChanges(items: [PushItem]) async throws -> [PushItem] {
        let records = items.map { item -> CKRecord in
            let recordId = CKRecord.ID(recordName: item.id, zoneID: zoneID)
            let record = CKRecord(recordType: item.type, recordID: recordId)
            return record.from(dict: item.itemDict)
        }
        _ = try await pushChanges(records: records)
        return items
    }

    func pushChanges(records: [CKRecord]) async throws -> [CKRecord] {
        let chunckedList = records.chunked(into: 200)
        var modifiedRecords = [CKRecord]()
        for chunck in chunckedList {
            let (modified, _) = try await modifyRecords(saving: chunck, deleting: [], savePolicy: .changedKeys)
            modifiedRecords.append(contentsOf: modified ?? [])
        }
        return modifiedRecords
    }

    func pullChanges(
        since token: CKServerChangeToken? = UserDefaults.serverChangeToken()
    ) async throws -> ([CKRecord], CKServerChangeToken?, Bool){
        return try await withCheckedThrowingContinuation { continuation -> Void in
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            options.previousServerChangeToken = token
            let changesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: [zoneID: options])
            var records = [CKRecord]()
            changesOperation.recordChangedBlock = { record in
                records.append(record)
            }
            changesOperation.recordZoneFetchCompletionBlock = { _, serverToken, _, moreComing, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (records, serverToken, moreComing))
                }
            }
            privateDB.add(changesOperation)
        }
    }

    func modifyRecords(
        saving: [CKRecord],
        deleting: [CKRecord.ID],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .changedKeys
    ) async throws -> ([CKRecord]?, [CKRecord.ID]?) {
        return try await withCheckedThrowingContinuation { continuation -> Void in
            let operation = CKModifyRecordsOperation(recordsToSave: saving, recordIDsToDelete: deleting)
            operation.savePolicy = savePolicy
            operation.modifyRecordsCompletionBlock = { (records, deletingIDs, error) in
                print("CloudKit modify complete: \(error?.localizedDescription ?? "nil")")
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (records, deletingIDs))
                }
            }
            privateDB.add(operation)
        }
    }
}

extension CKRecord {

    func from(dict: [String: Any]) -> CKRecord {
        for (key, value) in dict {
            self[key] = value as? __CKRecordObjCValue
        }
        return self
    }
}

enum RecordType: String {
    case conversation = "Conversation"
    case chatMessage = "ChatMessage"
}

protocol Pushable {
    var recordId: String { get }
    var recordType: RecordType { get }
    var recordObjectJson: String { get }
    var recordDict: [String: Any] { get }
    func toPushItem() -> PushItem
}

extension Pushable {
    func toPushItem() -> PushItem {
        return PushItem(id: recordId, type: recordType.rawValue, itemObject: recordObjectJson)
    }

    var recordObjectJson: String {
        let jsonData = try! JSONSerialization.data(withJSONObject: recordDict, options: [])
        return String(bytes: jsonData, encoding: .utf8)!
    }
}

protocol Recordable {
    var id: String { get set }
    var timeCreated: Int { get set }
    var timeRemoved: Int { get set }
}

typealias PushableObject = BlackbirdModel&Pushable&Recordable
