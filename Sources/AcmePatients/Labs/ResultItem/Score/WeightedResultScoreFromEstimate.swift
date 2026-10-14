import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelEstimatesForScore(_ items: [AdaptivePanelEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveWeightedResultScoresFromEstimate(_ items: [AdaptivePanelEstimate]) -> [WeightedResultScore] {
        var out: [WeightedResultScore] = []
        for item in items {
            let derived = newWeightedResultScore(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWeightedResultScore(_ item: WeightedResultScore) -> String {
        return normalizeScheduledPanelGroupCode(item.code)
    }
}
