import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionEstimatesForProposal(_ items: [SubstitutionEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRegionalRecallProposalsFromEstimate(_ items: [SubstitutionEstimate]) -> [RegionalRecallProposal] {
        var out: [RegionalRecallProposal] = []
        for item in items {
            let derived = newRegionalRecallProposal(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRegionalRecallProposal(_ item: RegionalRecallProposal) -> String {
        return classifyGlobalSubstitutionScore(item.adjustedVolume())
    }
}
