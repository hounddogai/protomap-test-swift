import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedRiskScoreTiersForDigest(_ items: [WeightedRiskScoreTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRiskScoreDigestsFromTier(_ items: [WeightedRiskScoreTier]) -> [RiskScoreDigest] {
        var out: [RiskScoreDigest] = []
        for item in items {
            let derived = newRiskScoreDigest(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRiskScoreDigest(_ item: RiskScoreDigest) -> String {
        return normalizeWeightedRiskScoreTierCode(item.code)
    }
}
