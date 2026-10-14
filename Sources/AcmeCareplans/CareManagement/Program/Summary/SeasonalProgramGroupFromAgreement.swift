import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalAgreementsForGroup(_ items: [GoalAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveSeasonalProgramGroupsFromAgreement(_ items: [GoalAgreement]) -> [SeasonalProgramGroup] {
        var out: [SeasonalProgramGroup] = []
        for item in items {
            let derived = newSeasonalProgramGroup(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceSeasonalProgramGroup(_ item: SeasonalProgramGroup) -> String {
        return classifyGoalScore(item.netExposure())
    }
}
