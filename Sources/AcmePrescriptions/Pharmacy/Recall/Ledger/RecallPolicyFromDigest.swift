import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInteractionDigestsForPolicy(_ items: [AdaptiveInteractionDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRecallPoliciesFromDigest(_ items: [AdaptiveInteractionDigest]) -> [RecallPolicy] {
        var out: [RecallPolicy] = []
        for item in items {
            let derived = newRecallPolicy(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRecallPolicy(_ item: RecallPolicy) -> String {
        return adaptiveInteractionDigestBucket(item.projectedTotal())
    }
}
