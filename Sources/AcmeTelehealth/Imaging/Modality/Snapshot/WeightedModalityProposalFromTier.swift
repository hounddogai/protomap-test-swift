import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadTiersForProposal(_ items: [TieredReadTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveWeightedModalityProposalsFromTier(_ items: [TieredReadTier]) -> [WeightedModalityProposal] {
        var out: [WeightedModalityProposal] = []
        for item in items {
            let derived = newWeightedModalityProposal(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceWeightedModalityProposal(_ item: WeightedModalityProposal) -> String {
        return tieredReadTierBucket(item.measuredValue())
    }
}
