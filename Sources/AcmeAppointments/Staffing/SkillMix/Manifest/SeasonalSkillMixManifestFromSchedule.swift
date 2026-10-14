import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingSkillMixSchedulesForManifest(_ items: [RollingSkillMixSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveSeasonalSkillMixManifestsFromSchedule(_ items: [RollingSkillMixSchedule]) -> [SeasonalSkillMixManifest] {
        var out: [SeasonalSkillMixManifest] = []
        for item in items {
            let derived = newSeasonalSkillMixManifest(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignSeasonalSkillMixManifest(_ item: SeasonalSkillMixManifest) -> Double {
        return skillMixOverrideWeight(9, active: true)
    }
}
