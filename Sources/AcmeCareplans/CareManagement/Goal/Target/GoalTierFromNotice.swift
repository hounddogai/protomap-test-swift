import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyProgramNoticesForTier(_ items: [LegacyProgramNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveGoalTiersFromNotice(_ items: [LegacyProgramNotice]) -> [GoalTier] {
        var out: [GoalTier] = []
        for item in items {
            let derived = newGoalTier(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveGoalTier(_ item: GoalTier) -> Double {
        return programGroupWeight(9, active: true)
    }
}
