import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInteractionScoresForClaim(_ items: [AdaptiveInteractionScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveInteractionClaimsFromScore(_ items: [AdaptiveInteractionScore]) -> [InteractionClaim] {
        var out: [InteractionClaim] = []
        for item in items {
            let derived = newInteractionClaim(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreInteractionClaim(_ item: InteractionClaim) -> String {
        return classifyAdaptiveInteractionScore(item.netVolume())
    }
}
