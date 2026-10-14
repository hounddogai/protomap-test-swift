import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientProxyClaimsForBudget(_ items: [LenientProxyClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePrimaryLanguageBudgetsFromClaim(_ items: [LenientProxyClaim]) -> [PrimaryLanguageBudget] {
        var out: [PrimaryLanguageBudget] = []
        for item in items {
            let derived = newPrimaryLanguageBudget(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryLanguageBudget(_ item: PrimaryLanguageBudget) -> Double {
        return lenientProxyClaimWeight(9, active: true)
    }
}
