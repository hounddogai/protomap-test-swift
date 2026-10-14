import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementMetricsForDraft(_ items: [StatementMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDenialDraftsFromMetric(_ items: [StatementMetric]) -> [DenialDraft] {
        var out: [DenialDraft] = []
        for item in items {
            let derived = newDenialDraft(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDenialDraft(_ item: DenialDraft) -> String {
        return weightedStatementSummaryBucket(item.netLoad())
    }
}
