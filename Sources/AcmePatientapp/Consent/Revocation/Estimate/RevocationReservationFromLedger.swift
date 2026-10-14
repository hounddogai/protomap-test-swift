import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormLedgersForReservation(_ items: [ConsentFormLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRevocationReservationsFromLedger(_ items: [ConsentFormLedger]) -> [RevocationReservation] {
        var out: [RevocationReservation] = []
        for item in items {
            let derived = newRevocationReservation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchRevocationReservation(_ item: RevocationReservation) -> Double {
        return consentFormClaimWeight(4, active: true)
    }
}
