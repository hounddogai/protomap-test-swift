import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeBatchedModalityReviewsForSchedule(_ items: [BatchedModalityReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledPrioritySchedulesFromReview(_ items: [BatchedModalityReview]) -> [ScheduledPrioritySchedule] {
        var out: [ScheduledPrioritySchedule] = []
        for item in items {
            let derived = newScheduledPrioritySchedule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileScheduledPrioritySchedule(_ item: ScheduledPrioritySchedule) -> String {
        return modalitySnapshotBucket(item.measuredValue())
    }
}
