import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotEntriesForMetric(_ items: [SlotEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalFollowUpMetricsFromEntry(_ items: [SlotEntry]) -> [RegionalFollowUpMetric] {
        var out: [RegionalFollowUpMetric] = []
        for item in items {
            let derived = newRegionalFollowUpMetric(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalFollowUpMetric(_ item: RegionalFollowUpMetric) -> String {
        return normalizeRollingSlotRollupCode(item.code)
    }
}
