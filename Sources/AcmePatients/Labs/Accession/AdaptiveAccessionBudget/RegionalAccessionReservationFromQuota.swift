import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedSpecimenQuotasForReservation(_ items: [CappedSpecimenQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRegionalAccessionReservationsFromQuota(_ items: [CappedSpecimenQuota]) -> [RegionalAccessionReservation] {
        var out: [RegionalAccessionReservation] = []
        for item in items {
            let derived = newRegionalAccessionReservation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeRegionalAccessionReservation(_ item: RegionalAccessionReservation) -> String {
        return normalizeCappedSpecimenQuotaCode(item.code)
    }
}
