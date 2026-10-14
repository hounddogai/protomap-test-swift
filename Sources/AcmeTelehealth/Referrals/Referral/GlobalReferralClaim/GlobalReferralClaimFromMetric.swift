import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralMetricsForClaim(_ items: [ReferralMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalReferralClaimsFromMetric(_ items: [ReferralMetric]) -> [GlobalReferralClaim] {
        var out: [GlobalReferralClaim] = []
        for item in items {
            let derived = newGlobalReferralClaim(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalReferralClaim(_ item: GlobalReferralClaim) -> String {
        return referralMetricBucket(item.effectiveTotal())
    }
}
