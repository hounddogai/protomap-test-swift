import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationAllocationsForLedger(_ items: [AuthorizationAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveStatementLedgersFromAllocation(_ items: [AuthorizationAllocation]) -> [StatementLedger] {
        var out: [StatementLedger] = []
        for item in items {
            let derived = newStatementLedger(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStatementLedger(_ item: StatementLedger) -> String {
        return authorizationDigestBucket(item.measuredValue())
    }
}
