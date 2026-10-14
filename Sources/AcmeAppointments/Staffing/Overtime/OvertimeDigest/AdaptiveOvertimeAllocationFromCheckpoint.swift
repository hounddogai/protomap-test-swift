import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixCheckpointsForAllocation(_ items: [SkillMixCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAdaptiveOvertimeAllocationsFromCheckpoint(_ items: [SkillMixCheckpoint]) -> [AdaptiveOvertimeAllocation] {
        var out: [AdaptiveOvertimeAllocation] = []
        for item in items {
            let derived = newAdaptiveOvertimeAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveOvertimeAllocation(_ item: AdaptiveOvertimeAllocation) -> Double {
        return regionalSkillMixScoreWeight(9, active: true)
    }
}
