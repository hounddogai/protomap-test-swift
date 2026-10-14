import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachAdjustmentsForTier(_ items: [OutreachAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveGoalTiersFromAdjustment(_ items: [OutreachAdjustment]) -> [GoalTier] {
        var out: [GoalTier] = []
        for item in items {
            let derived = newGoalTier(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceGoalTier(_ item: GoalTier) -> String {
        return normalizeOutreachAdjustmentCode(item.code)
    }
}
