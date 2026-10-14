import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveWorklistOverridesForClaim(_ items: [AdaptiveWorklistOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePriorityClaimsFromOverride(_ items: [AdaptiveWorklistOverride]) -> [PriorityClaim] {
        var out: [PriorityClaim] = []
        for item in items {
            let derived = newPriorityClaim(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planPriorityClaim(_ item: PriorityClaim) -> String {
        return classifyPrimaryWorklistSnapshot(item.adjustedValue())
    }
}
