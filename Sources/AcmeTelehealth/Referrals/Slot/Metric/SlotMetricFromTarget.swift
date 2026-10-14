import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotTargetsForMetric(_ items: [SlotTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSlotMetricsFromTarget(_ items: [SlotTarget]) -> [SlotMetric] {
        var out: [SlotMetric] = []
        for item in items {
            let derived = newSlotMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchSlotMetric(_ item: SlotMetric) -> String {
        return normalizeSlotTargetCode(item.code)
    }
}
