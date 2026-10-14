import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureReviewsForTarget(_ items: [ClosureReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSlotTargetsFromReview(_ items: [ClosureReview]) -> [SlotTarget] {
        var out: [SlotTarget] = []
        for item in items {
            let derived = newSlotTarget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeSlotTarget(_ item: SlotTarget) -> Double {
        return rollingClosureNoticeWeight(5, active: true)
    }
}
