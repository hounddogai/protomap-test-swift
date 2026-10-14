import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalRoundingProposalsForEstimate(_ items: [RegionalRoundingProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveSeasonalTaskEstimatesFromProposal(_ items: [RegionalRoundingProposal]) -> [SeasonalTaskEstimate] {
        var out: [SeasonalTaskEstimate] = []
        for item in items {
            let derived = newSeasonalTaskEstimate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeSeasonalTaskEstimate(_ item: SeasonalTaskEstimate) -> String {
        return regionalRoundingProposalBucket(item.effectiveExposure())
    }
}
