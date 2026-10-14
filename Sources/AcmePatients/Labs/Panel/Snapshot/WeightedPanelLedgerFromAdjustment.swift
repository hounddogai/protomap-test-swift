import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyAccessionAdjustmentsForLedger(_ items: [LegacyAccessionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveWeightedPanelLedgersFromAdjustment(_ items: [LegacyAccessionAdjustment]) -> [WeightedPanelLedger] {
        var out: [WeightedPanelLedger] = []
        for item in items {
            let derived = newWeightedPanelLedger(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeWeightedPanelLedger(_ item: WeightedPanelLedger) -> String {
        return classifyRollingAccessionReservation(item.adjustedValue())
    }
}
