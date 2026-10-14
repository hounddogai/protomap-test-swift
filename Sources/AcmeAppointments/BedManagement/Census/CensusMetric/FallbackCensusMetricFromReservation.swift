import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultCleaningReservationsForMetric(_ items: [DefaultCleaningReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveFallbackCensusMetricsFromReservation(_ items: [DefaultCleaningReservation]) -> [FallbackCensusMetric] {
        var out: [FallbackCensusMetric] = []
        for item in items {
            let derived = newFallbackCensusMetric(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planFallbackCensusMetric(_ item: FallbackCensusMetric) -> String {
        return tieredCleaningSummaryBucket(item.weightedTotal())
    }
}
