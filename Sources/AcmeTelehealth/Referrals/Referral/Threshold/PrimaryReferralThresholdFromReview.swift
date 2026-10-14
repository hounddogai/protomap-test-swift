import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralReviewsForThreshold(_ items: [ReferralReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePrimaryReferralThresholdsFromReview(_ items: [ReferralReview]) -> [PrimaryReferralThreshold] {
        var out: [PrimaryReferralThreshold] = []
        for item in items {
            let derived = newPrimaryReferralThreshold(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryReferralThresholdExtra(_ item: PrimaryReferralThreshold) -> String {
        return normalizeLegacyReferralEntryCode(item.code)
    }
}
