import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionDigestsForTemplate(_ items: [InteractionDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRecallTemplatesFromDigest(_ items: [InteractionDigest]) -> [RecallTemplate] {
        var out: [RecallTemplate] = []
        for item in items {
            let derived = newRecallTemplate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRecallTemplate(_ item: RecallTemplate) -> Double {
        return interactionReviewWeight(3, active: true)
    }
}
