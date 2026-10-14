import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingCredentialAllocationsForPlan(_ items: [RollingCredentialAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSeasonalSkillMixPlansFromAllocation(_ items: [RollingCredentialAllocation]) -> [SeasonalSkillMixPlan] {
        var out: [SeasonalSkillMixPlan] = []
        for item in items {
            let derived = newSeasonalSkillMixPlan(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleSeasonalSkillMixPlan(_ item: SeasonalSkillMixPlan) -> String {
        return classifyRollingCredentialAllocation(item.netTotal())
    }
}
