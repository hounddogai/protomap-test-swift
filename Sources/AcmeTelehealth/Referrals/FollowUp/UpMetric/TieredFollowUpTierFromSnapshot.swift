import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredEligibilitySnapshotsForTier(_ items: [TieredEligibilitySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveTieredFollowUpTiersFromSnapshot(_ items: [TieredEligibilitySnapshot]) -> [TieredFollowUpTier] {
        var out: [TieredFollowUpTier] = []
        for item in items {
            let derived = newTieredFollowUpTier(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTieredFollowUpTier(_ item: TieredFollowUpTier) -> String {
        return tieredEligibilitySnapshotBucket(item.adjustedLoad())
    }
}
