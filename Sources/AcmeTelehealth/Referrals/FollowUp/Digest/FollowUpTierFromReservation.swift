import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedReferralReservationsForTier(_ items: [WeightedReferralReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveFollowUpTiersFromReservation(_ items: [WeightedReferralReservation]) -> [FollowUpTier] {
        var out: [FollowUpTier] = []
        for item in items {
            let derived = newFollowUpTier(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFollowUpTier(_ item: FollowUpTier) -> String {
        return referralMilestoneBucket(item.projectedExposure())
    }
}
