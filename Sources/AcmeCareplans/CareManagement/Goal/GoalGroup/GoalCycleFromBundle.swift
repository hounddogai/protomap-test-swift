import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalProgramBundlesForCycle(_ items: [SeasonalProgramBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGoalCyclesFromBundle(_ items: [SeasonalProgramBundle]) -> [GoalCycle] {
        var out: [GoalCycle] = []
        for item in items {
            let derived = newGoalCycle(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planGoalCycle(_ item: GoalCycle) -> String {
        return classifyRollingProgramBaseline(item.adjustedLoad())
    }
}
