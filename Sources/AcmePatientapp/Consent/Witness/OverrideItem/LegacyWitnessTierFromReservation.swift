import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingDisclosureReservationsForTier(_ items: [RollingDisclosureReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLegacyWitnessTiersFromReservation(_ items: [RollingDisclosureReservation]) -> [LegacyWitnessTier] {
        var out: [LegacyWitnessTier] = []
        for item in items {
            let derived = newLegacyWitnessTier(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLegacyWitnessTier(_ item: LegacyWitnessTier) -> String {
        return classifySeasonalDisclosureDigest(item.measuredValue())
    }
}
