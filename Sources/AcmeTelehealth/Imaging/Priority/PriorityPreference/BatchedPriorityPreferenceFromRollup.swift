import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadRollupsForPreference(_ items: [ReadRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveBatchedPriorityPreferencesFromRollup(_ items: [ReadRollup]) -> [BatchedPriorityPreference] {
        var out: [BatchedPriorityPreference] = []
        for item in items {
            let derived = newBatchedPriorityPreference(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedPriorityPreference(_ item: BatchedPriorityPreference) -> String {
        return readThresholdBucket(item.netTotal())
    }
}
