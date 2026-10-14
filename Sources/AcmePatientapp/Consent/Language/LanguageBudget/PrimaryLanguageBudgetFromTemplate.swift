import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalConsentFormTemplatesForBudget(_ items: [GlobalConsentFormTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePrimaryLanguageBudgetsFromTemplate(_ items: [GlobalConsentFormTemplate]) -> [PrimaryLanguageBudget] {
        var out: [PrimaryLanguageBudget] = []
        for item in items {
            let derived = newPrimaryLanguageBudget(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePrimaryLanguageBudget(_ item: PrimaryLanguageBudget) -> Double {
        return globalConsentFormTemplateWeight(3, active: true)
    }
}
