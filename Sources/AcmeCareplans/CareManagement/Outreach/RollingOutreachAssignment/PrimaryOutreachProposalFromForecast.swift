import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalForecastsForProposal(_ items: [GoalForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryOutreachProposalsFromForecast(_ items: [GoalForecast]) -> [PrimaryOutreachProposal] {
        var out: [PrimaryOutreachProposal] = []
        for item in items {
            let derived = newPrimaryOutreachProposal(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryOutreachProposal(_ item: PrimaryOutreachProposal) -> String {
        return normalizePendingGoalDigestCode(item.code)
    }
}
