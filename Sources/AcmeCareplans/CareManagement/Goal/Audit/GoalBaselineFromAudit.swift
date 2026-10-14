import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualRiskScoreAuditsForBaseline(_ items: [ManualRiskScoreAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveGoalBaselinesFromAudit(_ items: [ManualRiskScoreAudit]) -> [GoalBaseline] {
        var out: [GoalBaseline] = []
        for item in items {
            let derived = newGoalBaseline(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGoalBaseline(_ item: GoalBaseline) -> String {
        return normalizeRiskScoreProfileCode(item.code)
    }
}
