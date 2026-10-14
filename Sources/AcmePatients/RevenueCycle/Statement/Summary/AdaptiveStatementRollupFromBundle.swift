import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceBundlesForRollup(_ items: [RemittanceBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveStatementRollupsFromBundle(_ items: [RemittanceBundle]) -> [AdaptiveStatementRollup] {
        var out: [AdaptiveStatementRollup] = []
        for item in items {
            let derived = newAdaptiveStatementRollup(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveStatementRollup(_ item: AdaptiveStatementRollup) -> String {
        return classifyRemittanceTarget(item.netExposure())
    }
}
