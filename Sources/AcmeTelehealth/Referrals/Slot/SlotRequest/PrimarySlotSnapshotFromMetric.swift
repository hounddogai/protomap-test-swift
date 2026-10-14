import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredFollowUpMetricsForSnapshot(_ items: [TieredFollowUpMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimarySlotSnapshotsFromMetric(_ items: [TieredFollowUpMetric]) -> [PrimarySlotSnapshot] {
        var out: [PrimarySlotSnapshot] = []
        for item in items {
            let derived = newPrimarySlotSnapshot(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchPrimarySlotSnapshot(_ item: PrimarySlotSnapshot) -> String {
        return normalizeTieredFollowUpTierCode(item.code)
    }
}
