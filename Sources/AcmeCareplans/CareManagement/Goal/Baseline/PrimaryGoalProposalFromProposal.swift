import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultGoalProposalsForProposal(_ items: [DefaultGoalProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePrimaryGoalProposalsFromProposal(_ items: [DefaultGoalProposal]) -> [PrimaryGoalProposal] {
        var out: [PrimaryGoalProposal] = []
        for item in items {
            let derived = newPrimaryGoalProposal(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryGoalProposal(_ item: PrimaryGoalProposal) -> String {
        return classifyGoalReview(item.effectiveExposure())
    }
}
