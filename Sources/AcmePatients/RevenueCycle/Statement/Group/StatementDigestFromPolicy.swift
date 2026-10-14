import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittancePoliciesForDigest(_ items: [RemittancePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStatementDigestsFromPolicy(_ items: [RemittancePolicy]) -> [StatementDigest] {
        var out: [StatementDigest] = []
        for item in items {
            let derived = newStatementDigest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateStatementDigest(_ item: StatementDigest) -> String {
        return remittanceRuleBucket(item.adjustedLoad())
    }
}
