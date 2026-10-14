import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalLedgersForEstimate(_ items: [GoalLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDefaultRiskScoreEstimatesFromLedger(_ items: [GoalLedger]) -> [DefaultRiskScoreEstimate] {
        var out: [DefaultRiskScoreEstimate] = []
        for item in items {
            let derived = newDefaultRiskScoreEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitDefaultRiskScoreEstimate(_ item: DefaultRiskScoreEstimate) -> String {
        return normalizePrimaryGoalScoreCode(item.code)
    }
}
