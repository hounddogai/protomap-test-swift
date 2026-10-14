import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultChargeClaimsForReservation(_ items: [DefaultChargeClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRemittanceReservationsFromClaim(_ items: [DefaultChargeClaim]) -> [RemittanceReservation] {
        var out: [RemittanceReservation] = []
        for item in items {
            let derived = newRemittanceReservation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRemittanceReservation(_ item: RemittanceReservation) -> String {
        return normalizeDefaultChargeClaimCode(item.code)
    }
}
