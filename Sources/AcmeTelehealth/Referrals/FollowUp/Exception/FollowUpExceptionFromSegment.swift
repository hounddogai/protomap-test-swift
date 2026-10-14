import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilitySegmentsForException(_ items: [EligibilitySegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveFollowUpExceptionsFromSegment(_ items: [EligibilitySegment]) -> [FollowUpException] {
        var out: [FollowUpException] = []
        for item in items {
            let derived = newFollowUpException(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeFollowUpException(_ item: FollowUpException) -> String {
        return weightedEligibilitySlotBucket(item.netExposure())
    }
}
