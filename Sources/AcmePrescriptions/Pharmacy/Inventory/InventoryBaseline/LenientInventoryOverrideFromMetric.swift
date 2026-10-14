import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualRecallMetricsForOverride(_ items: [ManualRecallMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientInventoryOverridesFromMetric(_ items: [ManualRecallMetric]) -> [LenientInventoryOverride] {
        var out: [LenientInventoryOverride] = []
        for item in items {
            let derived = newLenientInventoryOverride(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreLenientInventoryOverride(_ item: LenientInventoryOverride) -> Double {
        return recallTargetWeight(1, active: true)
    }
}
