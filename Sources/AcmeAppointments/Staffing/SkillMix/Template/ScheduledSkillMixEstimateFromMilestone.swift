import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultAcuityPlanMilestonesForEstimate(_ items: [DefaultAcuityPlanMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledSkillMixEstimatesFromMilestone(_ items: [DefaultAcuityPlanMilestone]) -> [ScheduledSkillMixEstimate] {
        var out: [ScheduledSkillMixEstimate] = []
        for item in items {
            let derived = newScheduledSkillMixEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeScheduledSkillMixEstimate(_ item: ScheduledSkillMixEstimate) -> String {
        return classifyDefaultAcuityPlanMilestone(item.projectedExposure())
    }
}
