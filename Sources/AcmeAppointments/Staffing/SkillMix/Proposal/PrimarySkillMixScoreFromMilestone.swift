import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedSkillMixMilestonesForScore(_ items: [WeightedSkillMixMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func derivePrimarySkillMixScoresFromMilestone(_ items: [WeightedSkillMixMilestone]) -> [PrimarySkillMixScore] {
        var out: [PrimarySkillMixScore] = []
        for item in items {
            let derived = newPrimarySkillMixScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPrimarySkillMixScore(_ item: PrimarySkillMixScore) -> String {
        return normalizeSeasonalSkillMixAuditCode(item.code)
    }
}
