import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAdaptiveSkillMixReviewsForAllocation(_ items: [AdaptiveSkillMixReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingCredentialAllocationsFromReview(_ items: [AdaptiveSkillMixReview]) -> [RollingCredentialAllocation] {
        var out: [RollingCredentialAllocation] = []
        for item in items {
            let derived = newRollingCredentialAllocation(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingCredentialAllocation(_ item: RollingCredentialAllocation) -> String {
        return classifyPrimarySkillMixManifest(item.adjustedTotal())
    }
}
