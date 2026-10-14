import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementReviewsForMilestone(_ items: [StatementReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveDenialMilestonesFromReview(_ items: [StatementReview]) -> [DenialMilestone] {
        var out: [DenialMilestone] = []
        for item in items {
            let derived = newDenialMilestone(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDenialMilestone(_ item: DenialMilestone) -> String {
        return statementReviewBucket(item.projectedExposure())
    }
}
