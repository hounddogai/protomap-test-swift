import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryNetworkTiersForSnapshot(_ items: [PrimaryNetworkTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveBatchedSlotSnapshotsFromTier(_ items: [PrimaryNetworkTier]) -> [BatchedSlotSnapshot] {
        var out: [BatchedSlotSnapshot] = []
        for item in items {
            let derived = newBatchedSlotSnapshot(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedSlotSnapshot(_ item: BatchedSlotSnapshot) -> String {
        return normalizeGlobalNetworkRecordCode(item.code)
    }
}
