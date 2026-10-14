import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictModalityPoliciesForBudget(_ items: [StrictModalityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveAdaptiveCareProtocolBudgetsFromPolicy(_ items: [StrictModalityPolicy]) -> [AdaptiveCareProtocolBudget] {
        var out: [AdaptiveCareProtocolBudget] = []
        for item in items {
            let derived = newAdaptiveCareProtocolBudget(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveCareProtocolBudget(_ item: AdaptiveCareProtocolBudget) -> String {
        return normalizeCappedModalityPreferenceCode(item.code)
    }
}
