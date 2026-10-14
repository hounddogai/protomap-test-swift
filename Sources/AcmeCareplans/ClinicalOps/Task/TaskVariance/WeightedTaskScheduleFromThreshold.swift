import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyOrderSetThresholdsForSchedule(_ items: [LegacyOrderSetThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWeightedTaskSchedulesFromThreshold(_ items: [LegacyOrderSetThreshold]) -> [WeightedTaskSchedule] {
        var out: [WeightedTaskSchedule] = []
        for item in items {
            let derived = newWeightedTaskSchedule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedTaskSchedule(_ item: WeightedTaskSchedule) -> Double {
        return legacyOrderSetThresholdWeight(7, active: true)
    }
}
