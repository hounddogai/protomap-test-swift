import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationCyclesForRollup(_ items: [AuthorizationCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveStatementRollupsFromCycle(_ items: [AuthorizationCycle]) -> [AdaptiveStatementRollup] {
        var out: [AdaptiveStatementRollup] = []
        for item in items {
            let derived = newAdaptiveStatementRollup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveStatementRollup(_ item: AdaptiveStatementRollup) -> String {
        return classifyScheduledAuthorizationMilestone(item.netExposure())
    }
}
