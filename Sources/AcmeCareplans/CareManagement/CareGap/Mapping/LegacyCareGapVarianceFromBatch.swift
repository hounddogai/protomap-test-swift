import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingGoalBatchesForVariance(_ items: [RollingGoalBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyCareGapVariancesFromBatch(_ items: [RollingGoalBatch]) -> [LegacyCareGapVariance] {
        var out: [LegacyCareGapVariance] = []
        for item in items {
            let derived = newLegacyCareGapVariance(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyCareGapVariance(_ item: LegacyCareGapVariance) -> Double {
        return rollingGoalBatchWeight(9, active: true)
    }
}
