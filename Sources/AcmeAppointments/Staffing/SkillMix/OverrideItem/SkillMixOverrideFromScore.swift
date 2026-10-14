import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanScoresForOverride(_ items: [AcuityPlanScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveSkillMixOverridesFromScore(_ items: [AcuityPlanScore]) -> [SkillMixOverride] {
        var out: [SkillMixOverride] = []
        for item in items {
            let derived = newSkillMixOverride(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreSkillMixOverride(_ item: SkillMixOverride) -> String {
        return normalizeAdaptiveAcuityPlanClaimCode(item.code)
    }
}
