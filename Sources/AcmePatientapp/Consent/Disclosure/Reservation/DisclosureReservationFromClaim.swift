import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageClaimsForReservation(_ items: [LanguageClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDisclosureReservationsFromClaim(_ items: [LanguageClaim]) -> [DisclosureReservation] {
        var out: [DisclosureReservation] = []
        for item in items {
            let derived = newDisclosureReservation(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveDisclosureReservation(_ item: DisclosureReservation) -> Double {
        return languageClaimWeight(7, active: true)
    }
}
