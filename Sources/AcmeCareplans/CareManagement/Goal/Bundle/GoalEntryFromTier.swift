import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedRiskScoreTiersForEntry(_ items: [WeightedRiskScoreTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveGoalEntriesFromTier(_ items: [WeightedRiskScoreTier]) -> [GoalEntry] {
        var out: [GoalEntry] = []
        for item in items {
            let derived = newGoalEntry(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGoalEntry(_ item: GoalEntry) -> String {
        return seasonalRiskScoreReservationBucket(item.effectiveVolume())
    }
}
