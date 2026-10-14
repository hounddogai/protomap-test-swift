import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryOvertimeAllocationsForManifest(_ items: [PrimaryOvertimeAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCappedSkillMixManifestsFromAllocation(_ items: [PrimaryOvertimeAllocation]) -> [CappedSkillMixManifest] {
        var out: [CappedSkillMixManifest] = []
        for item in items {
            let derived = newCappedSkillMixManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCappedSkillMixManifest(_ item: CappedSkillMixManifest) -> String {
        return classifyPrimaryOvertimeAllocation(item.weightedTotal())
    }
}
