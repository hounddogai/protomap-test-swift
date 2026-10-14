import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedClosureAdjustmentsForAssignment(_ items: [WeightedClosureAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFallbackEligibilityAssignmentsFromAdjustment(_ items: [WeightedClosureAdjustment]) -> [FallbackEligibilityAssignment] {
        var out: [FallbackEligibilityAssignment] = []
        for item in items {
            let derived = newFallbackEligibilityAssignment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackEligibilityAssignment(_ item: FallbackEligibilityAssignment) -> String {
        return closureEstimateBucket(item.adjustedVolume())
    }
}
