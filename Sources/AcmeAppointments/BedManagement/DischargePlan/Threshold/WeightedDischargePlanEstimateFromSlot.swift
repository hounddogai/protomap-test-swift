import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningSlotsForEstimate(_ items: [CleaningSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedDischargePlanEstimatesFromSlot(_ items: [CleaningSlot]) -> [WeightedDischargePlanEstimate] {
        var out: [WeightedDischargePlanEstimate] = []
        for item in items {
            let derived = newWeightedDischargePlanEstimate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedDischargePlanEstimate(_ item: WeightedDischargePlanEstimate) -> String {
        return classifyCleaningRollup(item.adjustedTotal())
    }
}
