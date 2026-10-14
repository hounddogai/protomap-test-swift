import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryLanguageBudgetsForThreshold(_ items: [PrimaryLanguageBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveLegacyDisclosureThresholdsFromBudget(_ items: [PrimaryLanguageBudget]) -> [LegacyDisclosureThreshold] {
        var out: [LegacyDisclosureThreshold] = []
        for item in items {
            let derived = newLegacyDisclosureThreshold(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }
}
