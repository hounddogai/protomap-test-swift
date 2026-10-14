import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveFollowUpPoliciesForAdjustment(_ items: [AdaptiveFollowUpPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveFollowUpAdjustmentsFromPolicy(_ items: [AdaptiveFollowUpPolicy]) -> [FollowUpAdjustment] {
        var out: [FollowUpAdjustment] = []
        for item in items {
            let derived = newFollowUpAdjustment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeFollowUpAdjustment(_ item: FollowUpAdjustment) -> String {
        return adaptiveFollowUpPolicyBucket(item.effectiveTotal())
    }
}
