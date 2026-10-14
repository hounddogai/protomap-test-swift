import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyFollowUpAuditsForReview(_ items: [LegacyFollowUpAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveReferralReviewsFromAudit(_ items: [LegacyFollowUpAudit]) -> [ReferralReview] {
        var out: [ReferralReview] = []
        for item in items {
            let derived = newReferralReview(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreReferralReview(_ item: ReferralReview) -> String {
        return followUpExceptionBucket(item.projectedTotal())
    }
}
