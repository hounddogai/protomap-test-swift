import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalHandoffBudgetsForRollup(_ items: [SeasonalHandoffBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveStrictOrderSetRollupsFromBudget(_ items: [SeasonalHandoffBudget]) -> [StrictOrderSetRollup] {
        var out: [StrictOrderSetRollup] = []
        for item in items {
            let derived = newStrictOrderSetRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeStrictOrderSetRollup(_ item: StrictOrderSetRollup) -> String {
        return normalizeHandoffDigestCode(item.code)
    }
}
