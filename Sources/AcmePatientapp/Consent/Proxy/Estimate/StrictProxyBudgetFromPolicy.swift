import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationPoliciesForBudget(_ items: [RevocationPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictProxyBudgetsFromPolicy(_ items: [RevocationPolicy]) -> [StrictProxyBudget] {
        var out: [StrictProxyBudget] = []
        for item in items {
            let derived = newStrictProxyBudget(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectStrictProxyBudgetExtra(_ item: StrictProxyBudget) -> String {
        return normalizeRevocationSnapshotCode(item.code)
    }
}
