import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyManifestsForReview(_ items: [ProxyManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveScheduledRevocationReviewsFromManifest(_ items: [ProxyManifest]) -> [ScheduledRevocationReview] {
        var out: [ScheduledRevocationReview] = []
        for item in items {
            let derived = newScheduledRevocationReview(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateScheduledRevocationReview(_ item: ScheduledRevocationReview) -> String {
        return classifyPrimaryProxyPolicy(item.measuredValue())
    }
}
