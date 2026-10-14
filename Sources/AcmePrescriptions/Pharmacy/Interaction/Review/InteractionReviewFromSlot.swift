import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallSlotsForReview(_ items: [RecallSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveInteractionReviewsFromSlot(_ items: [RecallSlot]) -> [InteractionReview] {
        var out: [InteractionReview] = []
        for item in items {
            let derived = newInteractionReview(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeInteractionReview(_ item: InteractionReview) -> String {
        return classifyRecallRollup(item.adjustedVolume())
    }
}
