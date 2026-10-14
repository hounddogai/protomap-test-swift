import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedDischargePlanMetricsForThreshold(_ items: [WeightedDischargePlanMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveTransferThresholdsFromMetric(_ items: [WeightedDischargePlanMetric]) -> [TransferThreshold] {
        var out: [TransferThreshold] = []
        for item in items {
            let derived = newTransferThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectTransferThreshold(_ item: TransferThreshold) -> String {
        return normalizeWeightedDischargePlanMetricCode(item.code)
    }
}
