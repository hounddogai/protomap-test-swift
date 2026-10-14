import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingRequestsForBatch(_ items: [SeasonalRoundingRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveFallbackOrderSetBatchesFromRequest(_ items: [SeasonalRoundingRequest]) -> [FallbackOrderSetBatch] {
        var out: [FallbackOrderSetBatch] = []
        for item in items {
            let derived = newFallbackOrderSetBatch(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackOrderSetBatch(_ item: FallbackOrderSetBatch) -> String {
        return normalizeFallbackRoundingMetricCode(item.code)
    }
}
