import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationOverridesForReservation(_ items: [AuthorizationOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDefaultRemittanceReservationsFromOverride(_ items: [AuthorizationOverride]) -> [DefaultRemittanceReservation] {
        var out: [DefaultRemittanceReservation] = []
        for item in items {
            let derived = newDefaultRemittanceReservation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultRemittanceReservation(_ item: DefaultRemittanceReservation) -> String {
        return fallbackAuthorizationAssignmentBucket(item.projectedExposure())
    }
}
