import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientClaimSummariesForBundle(_ items: [LenientClaimSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStatementBundlesFromSummary(_ items: [LenientClaimSummary]) -> [StatementBundle] {
        var out: [StatementBundle] = []
        for item in items {
            let derived = newStatementBundle(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreStatementBundle(_ item: StatementBundle) -> String {
        return pendingClaimBudgetBucket(item.effectiveVolume())
    }
}
