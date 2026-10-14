import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientReferenceRangeMetricsForEntry(_ items: [LenientReferenceRangeMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveResultEntriesFromMetric(_ items: [LenientReferenceRangeMetric]) -> [ResultEntry] {
        var out: [ResultEntry] = []
        for item in items {
            let derived = newResultEntry(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitResultEntry(_ item: ResultEntry) -> String {
        return normalizePendingReferenceRangeProfileCode(item.code)
    }
}
