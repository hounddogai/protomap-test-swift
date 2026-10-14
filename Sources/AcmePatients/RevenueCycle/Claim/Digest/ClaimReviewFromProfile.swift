import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeProfilesForReview(_ items: [ChargeProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveClaimReviewsFromProfile(_ items: [ChargeProfile]) -> [ClaimReview] {
        var out: [ClaimReview] = []
        for item in items {
            let derived = newClaimReview(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreClaimReview(_ item: ClaimReview) -> Double {
        return chargeNoticeWeight(4, active: true)
    }
}
