import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingRemittanceAllocationsForTier(_ items: [PendingRemittanceAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStatementTiersFromAllocation(_ items: [PendingRemittanceAllocation]) -> [StatementTier] {
        var out: [StatementTier] = []
        for item in items {
            let derived = newStatementTier(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateStatementTier(_ item: StatementTier) -> String {
        return normalizeRemittanceSnapshotCode(item.code)
    }
}
