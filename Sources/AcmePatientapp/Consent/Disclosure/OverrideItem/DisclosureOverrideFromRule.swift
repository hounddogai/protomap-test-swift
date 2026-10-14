import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedConsentFormRulesForOverride(_ items: [CappedConsentFormRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveDisclosureOverridesFromRule(_ items: [CappedConsentFormRule]) -> [DisclosureOverride] {
        var out: [DisclosureOverride] = []
        for item in items {
            let derived = newDisclosureOverride(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveDisclosureOverride(_ item: DisclosureOverride) -> String {
        return classifyConsentFormSummary(item.adjustedLoad())
    }
}
