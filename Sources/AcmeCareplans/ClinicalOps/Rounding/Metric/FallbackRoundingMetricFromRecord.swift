import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffRecordsForMetric(_ items: [HandoffRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFallbackRoundingMetricsFromRecord(_ items: [HandoffRecord]) -> [FallbackRoundingMetric] {
        var out: [FallbackRoundingMetric] = []
        for item in items {
            let derived = newFallbackRoundingMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFallbackRoundingMetric(_ item: FallbackRoundingMetric) -> String {
        return weightedHandoffExceptionBucket(item.effectiveExposure())
    }
}
