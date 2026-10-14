import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledGoalSegmentsForBundle(_ items: [ScheduledGoalSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAdaptiveCareGapBundlesFromSegment(_ items: [ScheduledGoalSegment]) -> [AdaptiveCareGapBundle] {
        var out: [AdaptiveCareGapBundle] = []
        for item in items {
            let derived = newAdaptiveCareGapBundle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveCareGapBundle(_ item: AdaptiveCareGapBundle) -> String {
        return scheduledGoalSegmentBucket(item.adjustedTotal())
    }
}
