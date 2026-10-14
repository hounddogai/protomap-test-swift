import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementEntriesForBundle(_ items: [StatementEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveAuthorizationBundlesFromEntry(_ items: [StatementEntry]) -> [AuthorizationBundle] {
        var out: [AuthorizationBundle] = []
        for item in items {
            let derived = newAuthorizationBundle(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateAuthorizationBundle(_ item: AuthorizationBundle) -> Double {
        return statementVarianceWeight(3, active: true)
    }
}
