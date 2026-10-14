import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedReferralSegmentsForRollup(_ items: [WeightedReferralSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRollingSlotRollupsFromSegment(_ items: [WeightedReferralSegment]) -> [RollingSlotRollup] {
        var out: [RollingSlotRollup] = []
        for item in items {
            let derived = newRollingSlotRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingSlotRollup(_ item: RollingSlotRollup) -> String {
        return classifyWeightedReferralSegment(item.projectedValue())
    }
}
