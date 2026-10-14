import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledAcuityPlanAllocationsForCycle(_ items: [ScheduledAcuityPlanAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedSkillMixCyclesFromAllocation(_ items: [ScheduledAcuityPlanAllocation]) -> [BatchedSkillMixCycle] {
        var out: [BatchedSkillMixCycle] = []
        for item in items {
            let derived = newBatchedSkillMixCycle(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectBatchedSkillMixCycle(_ item: BatchedSkillMixCycle) -> String {
        return classifyLegacyAcuityPlanMapping(item.weightedLoad())
    }
}
