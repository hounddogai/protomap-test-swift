import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureReviewsForClaim(_ items: [DisclosureReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveBatchedProxyClaimsFromReview(_ items: [DisclosureReview]) -> [BatchedProxyClaim] {
        var out: [BatchedProxyClaim] = []
        for item in items {
            let derived = newBatchedProxyClaim(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedProxyClaim(_ item: BatchedProxyClaim) -> String {
        return normalizeBatchedDisclosurePlanCode(item.code)
    }
}
