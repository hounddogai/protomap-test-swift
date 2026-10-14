import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralSegmentsForMilestone(_ items: [ReferralSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveTieredReferralMilestonesFromSegment(_ items: [ReferralSegment]) -> [TieredReferralMilestone] {
        var out: [TieredReferralMilestone] = []
        for item in items {
            let derived = newTieredReferralMilestone(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleTieredReferralMilestone(_ item: TieredReferralMilestone) -> String {
        return referralPolicyBucket(item.weightedVolume())
    }
}
