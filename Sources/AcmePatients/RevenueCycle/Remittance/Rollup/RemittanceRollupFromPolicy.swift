import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementPoliciesForRollup(_ items: [StatementPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRemittanceRollupsFromPolicy(_ items: [StatementPolicy]) -> [RemittanceRollup] {
        var out: [RemittanceRollup] = []
        for item in items {
            let derived = newRemittanceRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchRemittanceRollup(_ item: RemittanceRollup) -> String {
        return fallbackStatementAssignmentBucket(item.weightedValue())
    }
}
