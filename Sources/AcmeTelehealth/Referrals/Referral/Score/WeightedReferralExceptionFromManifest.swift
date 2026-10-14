import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedFollowUpManifestsForException(_ items: [WeightedFollowUpManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedReferralExceptionsFromManifest(_ items: [WeightedFollowUpManifest]) -> [WeightedReferralException] {
        var out: [WeightedReferralException] = []
        for item in items {
            let derived = newWeightedReferralException(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeWeightedReferralException(_ item: WeightedReferralException) -> Double {
        return tieredFollowUpReservationWeight(7, active: true)
    }
}
