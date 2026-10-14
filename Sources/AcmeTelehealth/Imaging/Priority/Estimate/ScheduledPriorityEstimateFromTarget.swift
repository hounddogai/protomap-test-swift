import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryStudyTargetsForEstimate(_ items: [PrimaryStudyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveScheduledPriorityEstimatesFromTarget(_ items: [PrimaryStudyTarget]) -> [ScheduledPriorityEstimate] {
        var out: [ScheduledPriorityEstimate] = []
        for item in items {
            let derived = newScheduledPriorityEstimate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledPriorityEstimate(_ item: ScheduledPriorityEstimate) -> Double {
        return primaryStudyReviewWeight(8, active: true)
    }
}
