import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingSpecimenMetricsForSchedule(_ items: [PendingSpecimenMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientResultSchedulesFromMetric(_ items: [PendingSpecimenMetric]) -> [LenientResultSchedule] {
        var out: [LenientResultSchedule] = []
        for item in items {
            let derived = newLenientResultSchedule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientResultSchedule(_ item: LenientResultSchedule) -> String {
        return normalizeFallbackSpecimenTierCode(item.code)
    }
}
