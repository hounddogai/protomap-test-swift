import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledPanelAdjustmentsForDigest(_ items: [ScheduledPanelAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptivePanelDigestsFromAdjustment(_ items: [ScheduledPanelAdjustment]) -> [AdaptivePanelDigest] {
        var out: [AdaptivePanelDigest] = []
        for item in items {
            let derived = newAdaptivePanelDigest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptivePanelDigest(_ item: AdaptivePanelDigest) -> Double {
        return scheduledPanelAdjustmentWeight(4, active: true)
    }
}
