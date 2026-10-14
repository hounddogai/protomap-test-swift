import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeEstimatesForPlan(_ items: [ChargeEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyAuthorizationPlansFromEstimate(_ items: [ChargeEstimate]) -> [LegacyAuthorizationPlan] {
        var out: [LegacyAuthorizationPlan] = []
        for item in items {
            let derived = newLegacyAuthorizationPlan(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLegacyAuthorizationPlan(_ item: LegacyAuthorizationPlan) -> String {
        return classifyChargeEstimate(item.measuredValue())
    }
}
