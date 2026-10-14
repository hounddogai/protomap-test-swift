import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInteractionTemplatesForPlan(_ items: [AdaptiveInteractionTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveInteractionPlansFromTemplate(_ items: [AdaptiveInteractionTemplate]) -> [InteractionPlan] {
        var out: [InteractionPlan] = []
        for item in items {
            let derived = newInteractionPlan(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveInteractionPlan(_ item: InteractionPlan) -> String {
        return cappedInteractionBaselineBucket(item.adjustedLoad())
    }
}
