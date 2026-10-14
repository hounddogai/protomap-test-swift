import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeStrictHandoffReservationsForReservation(_ items: [StrictHandoffReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyOrderSetReservationsFromReservation(_ items: [StrictHandoffReservation]) -> [LegacyOrderSetReservation] {
        var out: [LegacyOrderSetReservation] = []
        for item in items {
            let derived = newLegacyOrderSetReservation(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyOrderSetReservation(_ item: LegacyOrderSetReservation) -> String {
        return seasonalHandoffThresholdBucket(item.measuredValue())
    }
}
