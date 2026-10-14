import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftAssignmentsForMilestone(_ items: [ShiftAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSkillMixMilestonesFromAssignment(_ items: [ShiftAssignment]) -> [SkillMixMilestone] {
        var out: [SkillMixMilestone] = []
        for item in items {
            let derived = newSkillMixMilestone(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSkillMixMilestone(_ item: SkillMixMilestone) -> String {
        return normalizeShiftAssignmentCode(item.code)
    }
}
