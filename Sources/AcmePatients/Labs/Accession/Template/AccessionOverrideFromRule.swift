import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionRulesForOverride(_ items: [AccessionRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAccessionOverridesFromRule(_ items: [AccessionRule]) -> [AccessionOverride] {
        var out: [AccessionOverride] = []
        for item in items {
            let derived = newAccessionOverride(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAccessionOverride(_ item: AccessionOverride) -> String {
        return normalizeAccessionRuleCode(item.code)
    }
}
