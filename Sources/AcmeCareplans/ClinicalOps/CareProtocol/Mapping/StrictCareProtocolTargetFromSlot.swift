import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSlotsForTarget(_ items: [AlertSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveStrictCareProtocolTargetsFromSlot(_ items: [AlertSlot]) -> [StrictCareProtocolTarget] {
        var out: [StrictCareProtocolTarget] = []
        for item in items {
            let derived = newStrictCareProtocolTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeStrictCareProtocolTarget(_ item: StrictCareProtocolTarget) -> String {
        return alertScoreBucket(item.projectedValue())
    }
}
