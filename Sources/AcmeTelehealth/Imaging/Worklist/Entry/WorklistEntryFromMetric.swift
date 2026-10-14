import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyMetricsForEntry(_ items: [StudyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWorklistEntriesFromMetric(_ items: [StudyMetric]) -> [WorklistEntry] {
        var out: [WorklistEntry] = []
        for item in items {
            let derived = newWorklistEntry(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateWorklistEntry(_ item: WorklistEntry) -> String {
        return studyMetricBucket(item.netVolume())
    }
}
