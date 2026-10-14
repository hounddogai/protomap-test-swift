import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapWindowsForProposal(_ items: [CareGapWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRiskScoreProposalsFromWindow(_ items: [CareGapWindow]) -> [RiskScoreProposal] {
        var out: [RiskScoreProposal] = []
        for item in items {
            let derived = newRiskScoreProposal(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRiskScoreProposal(_ item: RiskScoreProposal) -> String {
        return normalizeCareGapBudgetCode(item.code)
    }
}
