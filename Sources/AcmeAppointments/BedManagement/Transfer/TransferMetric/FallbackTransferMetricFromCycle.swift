import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedCleaningCyclesForMetric(_ items: [BatchedCleaningCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFallbackTransferMetricsFromCycle(_ items: [BatchedCleaningCycle]) -> [FallbackTransferMetric] {
        var out: [FallbackTransferMetric] = []
        for item in items {
            let derived = newFallbackTransferMetric(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeFallbackTransferMetric(_ item: FallbackTransferMetric) -> Double {
        return batchedCleaningCycleWeight(6, active: true)
    }
}
