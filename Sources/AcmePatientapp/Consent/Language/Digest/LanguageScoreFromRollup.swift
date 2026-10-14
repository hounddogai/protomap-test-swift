import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedWitnessRollupsForScore(_ items: [WeightedWitnessRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveLanguageScoresFromRollup(_ items: [WeightedWitnessRollup]) -> [LanguageScore] {
        var out: [LanguageScore] = []
        for item in items {
            let derived = newLanguageScore(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileLanguageScore(_ item: LanguageScore) -> Double {
        return witnessSegmentWeight(6, active: true)
    }
}
