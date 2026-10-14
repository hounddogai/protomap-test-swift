import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualProxyMetricsForTier(_ items: [ManualProxyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRevocationTiersFromMetric(_ items: [ManualProxyMetric]) -> [RevocationTier] {
        var out: [RevocationTier] = []
        for item in items {
            let derived = newRevocationTier(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRevocationTier(_ item: RevocationTier) -> String {
        return scheduledProxyBatchBucket(item.projectedLoad())
    }
}
