import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingSkillMixManifestsForAllocation(_ items: [RollingSkillMixManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDefaultShiftAllocationsFromManifest(_ items: [RollingSkillMixManifest]) -> [DefaultShiftAllocation] {
        var out: [DefaultShiftAllocation] = []
        for item in items {
            let derived = newDefaultShiftAllocation(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultShiftAllocation(_ item: DefaultShiftAllocation) -> Double {
        return manualSkillMixMilestoneWeight(5, active: true)
    }
}
