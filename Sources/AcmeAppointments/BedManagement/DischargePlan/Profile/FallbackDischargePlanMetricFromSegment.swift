import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusSegmentsForMetric(_ items: [CensusSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveFallbackDischargePlanMetricsFromSegment(_ items: [CensusSegment]) -> [FallbackDischargePlanMetric] {
        var out: [FallbackDischargePlanMetric] = []
        for item in items {
            let derived = newFallbackDischargePlanMetric(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planFallbackDischargePlanMetric(_ item: FallbackDischargePlanMetric) -> String {
        return censusSegmentBucket(item.effectiveTotal())
    }
}
