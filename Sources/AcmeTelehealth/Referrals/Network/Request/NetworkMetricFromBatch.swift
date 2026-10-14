import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredFollowUpBatchesForMetric(_ items: [TieredFollowUpBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveNetworkMetricsFromBatch(_ items: [TieredFollowUpBatch]) -> [NetworkMetric] {
        var out: [NetworkMetric] = []
        for item in items {
            let derived = newNetworkMetric(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveNetworkMetric(_ item: NetworkMetric) -> String {
        return normalizeWeightedFollowUpSlotCode(item.code)
    }
}
