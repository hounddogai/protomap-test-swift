import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionMappingsForReview(_ items: [InteractionMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAdaptiveRecallReviewsFromMapping(_ items: [InteractionMapping]) -> [AdaptiveRecallReview] {
        var out: [AdaptiveRecallReview] = []
        for item in items {
            let derived = newAdaptiveRecallReview(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveRecallReview(_ item: AdaptiveRecallReview) -> Double {
        return interactionAuditWeight(5, active: true)
    }
}
