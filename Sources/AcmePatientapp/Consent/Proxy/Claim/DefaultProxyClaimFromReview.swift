import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationReviewsForClaim(_ items: [ScheduledRevocationReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultProxyClaimsFromReview(_ items: [ScheduledRevocationReview]) -> [DefaultProxyClaim] {
        var out: [DefaultProxyClaim] = []
        for item in items {
            let derived = newDefaultProxyClaim(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreDefaultProxyClaim(_ item: DefaultProxyClaim) -> String {
        return scheduledRevocationReviewBucket(item.netLoad())
    }
}
