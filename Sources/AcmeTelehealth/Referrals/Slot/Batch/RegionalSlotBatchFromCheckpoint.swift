import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyFollowUpCheckpointsForBatch(_ items: [LegacyFollowUpCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRegionalSlotBatchesFromCheckpoint(_ items: [LegacyFollowUpCheckpoint]) -> [RegionalSlotBatch] {
        var out: [RegionalSlotBatch] = []
        for item in items {
            let derived = newRegionalSlotBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRegionalSlotBatch(_ item: RegionalSlotBatch) -> String {
        return followUpRuleBucket(item.weightedExposure())
    }
}
