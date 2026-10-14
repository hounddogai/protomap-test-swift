import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictIsolationMilestonesForVariance(_ items: [StrictIsolationMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveWeightedTransferVariancesFromMilestone(_ items: [StrictIsolationMilestone]) -> [WeightedTransferVariance] {
        var out: [WeightedTransferVariance] = []
        for item in items {
            let derived = newWeightedTransferVariance(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedTransferVariance(_ item: WeightedTransferVariance) -> String {
        return classifyAdaptiveIsolationBaseline(item.adjustedTotal())
    }
}
