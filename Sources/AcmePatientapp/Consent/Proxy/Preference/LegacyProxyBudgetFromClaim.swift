import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureClaimsForBudget(_ items: [DisclosureClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyProxyBudgetsFromClaim(_ items: [DisclosureClaim]) -> [LegacyProxyBudget] {
        var out: [LegacyProxyBudget] = []
        for item in items {
            let derived = newLegacyProxyBudget(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyProxyBudget(_ item: LegacyProxyBudget) -> String {
        return classifyDisclosureTier(item.projectedValue())
    }
}
