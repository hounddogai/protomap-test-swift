import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityPoliciesForForecast(_ items: [EligibilityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePrimaryClosureForecastsFromPolicy(_ items: [EligibilityPolicy]) -> [PrimaryClosureForecast] {
        var out: [PrimaryClosureForecast] = []
        for item in items {
            let derived = newPrimaryClosureForecast(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPrimaryClosureForecast(_ item: PrimaryClosureForecast) -> String {
        return normalizeEligibilityPolicyCode(item.code)
    }
}
