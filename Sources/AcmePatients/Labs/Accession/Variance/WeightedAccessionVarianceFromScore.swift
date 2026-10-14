import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalPanelScoresForVariance(_ items: [SeasonalPanelScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveWeightedAccessionVariancesFromScore(_ items: [SeasonalPanelScore]) -> [WeightedAccessionVariance] {
        var out: [WeightedAccessionVariance] = []
        for item in items {
            let derived = newWeightedAccessionVariance(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeWeightedAccessionVariance(_ item: WeightedAccessionVariance) -> String {
        return strictPanelAssignmentBucket(item.measuredValue())
    }
}
