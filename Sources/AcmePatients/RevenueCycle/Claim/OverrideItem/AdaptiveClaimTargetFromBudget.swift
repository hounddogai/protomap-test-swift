import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledDenialBudgetsForTarget(_ items: [ScheduledDenialBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveClaimTargetsFromBudget(_ items: [ScheduledDenialBudget]) -> [AdaptiveClaimTarget] {
        var out: [AdaptiveClaimTarget] = []
        for item in items {
            let derived = newAdaptiveClaimTarget(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAdaptiveClaimTarget(_ item: AdaptiveClaimTarget) -> String {
        return classifyRegionalDenialClaim(item.netValue())
    }
}
