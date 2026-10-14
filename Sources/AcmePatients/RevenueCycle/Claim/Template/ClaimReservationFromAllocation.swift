import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementAllocationsForReservation(_ items: [StatementAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveClaimReservationsFromAllocation(_ items: [StatementAllocation]) -> [ClaimReservation] {
        var out: [ClaimReservation] = []
        for item in items {
            let derived = newClaimReservation(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyClaimReservation(_ item: ClaimReservation) -> String {
        return statementAllocationBucket(item.measuredValue())
    }
}
