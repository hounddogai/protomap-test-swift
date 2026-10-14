import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationBundlesForReview(_ items: [AuthorizationBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStatementReviewsFromBundle(_ items: [AuthorizationBundle]) -> [StatementReview] {
        var out: [StatementReview] = []
        for item in items {
            let derived = newStatementReview(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeStatementReview(_ item: StatementReview) -> String {
        return authorizationBundleBucket(item.adjustedTotal())
    }
}
