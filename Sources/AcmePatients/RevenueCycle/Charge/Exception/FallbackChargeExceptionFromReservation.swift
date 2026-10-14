import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationReservationsForException(_ items: [AuthorizationReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveFallbackChargeExceptionsFromReservation(_ items: [AuthorizationReservation]) -> [FallbackChargeException] {
        var out: [FallbackChargeException] = []
        for item in items {
            let derived = newFallbackChargeException(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackChargeException(_ item: FallbackChargeException) -> Double {
        return authorizationQuotaWeight(8, active: true)
    }
}
