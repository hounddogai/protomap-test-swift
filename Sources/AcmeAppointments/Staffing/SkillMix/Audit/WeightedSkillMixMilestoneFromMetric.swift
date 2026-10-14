import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalShiftMetricsForMilestone(_ items: [SeasonalShiftMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveWeightedSkillMixMilestonesFromMetric(_ items: [SeasonalShiftMetric]) -> [WeightedSkillMixMilestone] {
        var out: [WeightedSkillMixMilestone] = []
        for item in items {
            let derived = newWeightedSkillMixMilestone(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceWeightedSkillMixMilestone(_ item: WeightedSkillMixMilestone) -> String {
        return lenientShiftQuotaBucket(item.effectiveValue())
    }
}
