import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalStatementReservationsForOverride(_ items: [GlobalStatementReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveClaimOverridesFromReservation(_ items: [GlobalStatementReservation]) -> [ClaimOverride] {
        var out: [ClaimOverride] = []
        for item in items {
            let derived = newClaimOverride(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeClaimOverride(_ item: ClaimOverride) -> String {
        return normalizeGlobalStatementReservationCode(item.code)
    }
}
