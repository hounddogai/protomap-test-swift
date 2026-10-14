import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveClaimTargetsForScore(_ items: [AdaptiveClaimTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSeasonalChargeScoresFromTarget(_ items: [AdaptiveClaimTarget]) -> [SeasonalChargeScore] {
        var out: [SeasonalChargeScore] = []
        for item in items {
            let derived = newSeasonalChargeScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitSeasonalChargeScore(_ item: SeasonalChargeScore) -> Double {
        return adaptiveClaimTargetWeight(9, active: true)
    }
}
