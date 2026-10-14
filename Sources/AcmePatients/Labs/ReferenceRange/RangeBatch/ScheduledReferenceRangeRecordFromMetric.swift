import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedCourierMetricsForRecord(_ items: [CappedCourierMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveScheduledReferenceRangeRecordsFromMetric(_ items: [CappedCourierMetric]) -> [ScheduledReferenceRangeRecord] {
        var out: [ScheduledReferenceRangeRecord] = []
        for item in items {
            let derived = newScheduledReferenceRangeRecord(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeScheduledReferenceRangeRecord(_ item: ScheduledReferenceRangeRecord) -> Double {
        return courierAgreementWeight(5, active: true)
    }
}
