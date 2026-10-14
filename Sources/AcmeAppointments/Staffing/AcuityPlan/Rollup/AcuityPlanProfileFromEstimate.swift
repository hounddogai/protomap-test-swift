import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledSkillMixEstimatesForProfile(_ items: [ScheduledSkillMixEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveAcuityPlanProfilesFromEstimate(_ items: [ScheduledSkillMixEstimate]) -> [AcuityPlanProfile] {
        var out: [AcuityPlanProfile] = []
        for item in items {
            let derived = newAcuityPlanProfile(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeAcuityPlanProfile(_ item: AcuityPlanProfile) -> String {
        return classifyScheduledSkillMixEstimate(item.netVolume())
    }
}
