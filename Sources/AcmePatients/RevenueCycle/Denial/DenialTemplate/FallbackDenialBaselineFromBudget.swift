import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyClaimBudgetsForBaseline(_ items: [LegacyClaimBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackDenialBaselinesFromBudget(_ items: [LegacyClaimBudget]) -> [FallbackDenialBaseline] {
        var out: [FallbackDenialBaseline] = []
        for item in items {
            let derived = newFallbackDenialBaseline(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackDenialBaseline(_ item: FallbackDenialBaseline) -> Double {
        return legacyClaimBudgetWeight(4, active: true)
    }
}
