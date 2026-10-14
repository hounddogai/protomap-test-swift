import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRollupsForMetric(_ items: [ClosureRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSlotMetricsFromRollup(_ items: [ClosureRollup]) -> [SlotMetric] {
        var out: [SlotMetric] = []
        for item in items {
            let derived = newSlotMetric(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveSlotMetric(_ item: SlotMetric) -> String {
        return closureMappingBucket(item.netExposure())
    }
}
