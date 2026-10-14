import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualChargeOverridesForRollup(_ items: [ManualChargeOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveCappedStatementRollupsFromOverride(_ items: [ManualChargeOverride]) -> [CappedStatementRollup] {
        var out: [CappedStatementRollup] = []
        for item in items {
            let derived = newCappedStatementRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCappedStatementRollup(_ item: CappedStatementRollup) -> String {
        return normalizePendingChargeQuotaCode(item.code)
    }
}
