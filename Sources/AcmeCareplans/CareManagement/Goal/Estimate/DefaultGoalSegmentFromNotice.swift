import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingCareGapNoticesForSegment(_ items: [PendingCareGapNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDefaultGoalSegmentsFromNotice(_ items: [PendingCareGapNotice]) -> [DefaultGoalSegment] {
        var out: [DefaultGoalSegment] = []
        for item in items {
            let derived = newDefaultGoalSegment(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileDefaultGoalSegment(_ item: DefaultGoalSegment) -> String {
        return classifyRollingCareGapAdjustment(item.adjustedVolume())
    }
}
