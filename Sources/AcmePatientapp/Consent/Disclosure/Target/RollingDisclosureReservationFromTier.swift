import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalDisclosureTiersForReservation(_ items: [SeasonalDisclosureTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRollingDisclosureReservationsFromTier(_ items: [SeasonalDisclosureTier]) -> [RollingDisclosureReservation] {
        var out: [RollingDisclosureReservation] = []
        for item in items {
            let derived = newRollingDisclosureReservation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRollingDisclosureReservation(_ item: RollingDisclosureReservation) -> Double {
        return adaptiveDisclosureExceptionWeight(5, active: true)
    }
}
