import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceReviewsForMetric(_ items: [RemittanceReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStatementMetricsFromReview(_ items: [RemittanceReview]) -> [StatementMetric] {
        var out: [StatementMetric] = []
        for item in items {
            let derived = newStatementMetric(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStatementMetric(_ item: StatementMetric) -> String {
        return normalizeSeasonalRemittanceAssignmentCode(item.code)
    }
}
