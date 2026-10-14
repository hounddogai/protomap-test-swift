import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalRequestsForBaseline(_ items: [GoalRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingProgramBaselinesFromRequest(_ items: [GoalRequest]) -> [RollingProgramBaseline] {
        var out: [RollingProgramBaseline] = []
        for item in items {
            let derived = newRollingProgramBaseline(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingProgramBaselineExtra(_ item: RollingProgramBaseline) -> String {
        return goalClaimBucket(item.weightedVolume())
    }
}
