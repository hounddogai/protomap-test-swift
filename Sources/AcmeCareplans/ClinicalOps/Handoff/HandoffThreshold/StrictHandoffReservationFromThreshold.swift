import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyOrderSetThresholdsForReservation(_ items: [LegacyOrderSetThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveStrictHandoffReservationsFromThreshold(_ items: [LegacyOrderSetThreshold]) -> [StrictHandoffReservation] {
        var out: [StrictHandoffReservation] = []
        for item in items {
            let derived = newStrictHandoffReservation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStrictHandoffReservation(_ item: StrictHandoffReservation) -> String {
        return defaultOrderSetBatchBucket(item.measuredValue())
    }
}
