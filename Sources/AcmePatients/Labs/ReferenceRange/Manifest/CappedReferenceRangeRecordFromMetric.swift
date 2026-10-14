import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientReferenceRangeMetricsForRecord(_ items: [LenientReferenceRangeMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedReferenceRangeRecordsFromMetric(_ items: [LenientReferenceRangeMetric]) -> [CappedReferenceRangeRecord] {
        var out: [CappedReferenceRangeRecord] = []
        for item in items {
            let derived = newCappedReferenceRangeRecord(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCappedReferenceRangeRecord(_ item: CappedReferenceRangeRecord) -> String {
        return normalizePendingReferenceRangeProfileCode(item.code)
    }
}
