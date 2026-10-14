import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixScoresForAllocation(_ items: [SkillMixScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveGlobalShiftAllocationsFromScore(_ items: [SkillMixScore]) -> [GlobalShiftAllocation] {
        var out: [GlobalShiftAllocation] = []
        for item in items {
            let derived = newGlobalShiftAllocation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planGlobalShiftAllocation(_ item: GlobalShiftAllocation) -> String {
        return normalizeSkillMixScoreCode(item.code)
    }
}
