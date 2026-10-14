import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertDigestsForReview(_ items: [AlertDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRollingAlertReviewsFromDigest(_ items: [AlertDigest]) -> [RollingAlertReview] {
        var out: [RollingAlertReview] = []
        for item in items {
            let derived = newRollingAlertReview(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingAlertReview(_ item: RollingAlertReview) -> String {
        return alertLedgerBucket(item.projectedExposure())
    }
}
