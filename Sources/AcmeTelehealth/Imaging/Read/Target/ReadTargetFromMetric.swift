import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyMetricsForTarget(_ items: [StudyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveReadTargetsFromMetric(_ items: [StudyMetric]) -> [ReadTarget] {
        var out: [ReadTarget] = []
        for item in items {
            let derived = newReadTarget(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateReadTarget(_ item: ReadTarget) -> String {
        return studyMetricBucket(item.adjustedValue())
    }
}
