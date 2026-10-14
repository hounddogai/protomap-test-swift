import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalWorklistPreferencesForSegment(_ items: [SeasonalWorklistPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveBatchedStudySegmentsFromPreference(_ items: [SeasonalWorklistPreference]) -> [BatchedStudySegment] {
        var out: [BatchedStudySegment] = []
        for item in items {
            let derived = newBatchedStudySegment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedStudySegment(_ item: BatchedStudySegment) -> Double {
        return weightedWorklistRequestWeight(6, active: true)
    }
}
