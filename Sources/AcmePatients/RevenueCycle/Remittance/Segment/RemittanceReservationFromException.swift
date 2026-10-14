import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackClaimExceptionsForReservation(_ items: [FallbackClaimException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRemittanceReservationsFromException(_ items: [FallbackClaimException]) -> [RemittanceReservation] {
        var out: [RemittanceReservation] = []
        for item in items {
            let derived = newRemittanceReservation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectRemittanceReservation(_ item: RemittanceReservation) -> Double {
        return fallbackClaimExceptionWeight(2, active: true)
    }
}
