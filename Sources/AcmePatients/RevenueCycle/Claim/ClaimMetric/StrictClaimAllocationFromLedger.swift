import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultStatementLedgersForAllocation(_ items: [DefaultStatementLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveStrictClaimAllocationsFromLedger(_ items: [DefaultStatementLedger]) -> [StrictClaimAllocation] {
        var out: [StrictClaimAllocation] = []
        for item in items {
            let derived = newStrictClaimAllocation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitStrictClaimAllocation(_ item: StrictClaimAllocation) -> String {
        return fallbackStatementNoticeBucket(item.netVolume())
    }
}
