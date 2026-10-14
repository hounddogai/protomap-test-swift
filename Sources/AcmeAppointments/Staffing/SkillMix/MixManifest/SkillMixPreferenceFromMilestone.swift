import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixMilestonesForPreference(_ items: [SkillMixMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSkillMixPreferencesFromMilestone(_ items: [SkillMixMilestone]) -> [SkillMixPreference] {
        var out: [SkillMixPreference] = []
        for item in items {
            let derived = newSkillMixPreference(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeSkillMixPreference(_ item: SkillMixPreference) -> String {
        return manualSkillMixScheduleBucket(item.weightedVolume())
    }
}
