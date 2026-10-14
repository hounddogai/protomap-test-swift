import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryClosureProposalsForScore(_ items: [PrimaryClosureProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveEligibilityScoresFromProposal(_ items: [PrimaryClosureProposal]) -> [EligibilityScore] {
        var out: [EligibilityScore] = []
        for item in items {
            let derived = newEligibilityScore(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateEligibilityScore(_ item: EligibilityScore) -> Double {
        return primaryClosureProposalWeight(3, active: true)
    }
}
