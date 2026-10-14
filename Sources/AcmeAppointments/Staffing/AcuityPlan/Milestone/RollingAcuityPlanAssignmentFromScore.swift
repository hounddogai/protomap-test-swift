import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixScoresForAssignment(_ items: [SkillMixScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRollingAcuityPlanAssignmentsFromScore(_ items: [SkillMixScore]) -> [RollingAcuityPlanAssignment] {
        var out: [RollingAcuityPlanAssignment] = []
        for item in items {
            let derived = newRollingAcuityPlanAssignment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRollingAcuityPlanAssignment(_ item: RollingAcuityPlanAssignment) -> String {
        return normalizeSkillMixScoreCode(item.code)
    }
}
