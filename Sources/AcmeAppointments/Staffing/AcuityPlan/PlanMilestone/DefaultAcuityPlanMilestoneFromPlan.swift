import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalSkillMixPlansForMilestone(_ items: [SeasonalSkillMixPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveDefaultAcuityPlanMilestonesFromPlan(_ items: [SeasonalSkillMixPlan]) -> [DefaultAcuityPlanMilestone] {
        var out: [DefaultAcuityPlanMilestone] = []
        for item in items {
            let derived = newDefaultAcuityPlanMilestone(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultAcuityPlanMilestone(_ item: DefaultAcuityPlanMilestone) -> String {
        return normalizeGlobalSkillMixProposalCode(item.code)
    }
}
