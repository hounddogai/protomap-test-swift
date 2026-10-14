import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredNetworkDigestsForMilestone(_ items: [TieredNetworkDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveEligibilityMilestonesFromDigest(_ items: [TieredNetworkDigest]) -> [EligibilityMilestone] {
        var out: [EligibilityMilestone] = []
        for item in items {
            let derived = newEligibilityMilestone(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveEligibilityMilestone(_ item: EligibilityMilestone) -> String {
        return normalizeNetworkThresholdCode(item.code)
    }
}
