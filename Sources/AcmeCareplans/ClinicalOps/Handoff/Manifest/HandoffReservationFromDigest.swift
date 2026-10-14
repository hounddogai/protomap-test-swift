import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetDigestsForReservation(_ items: [OrderSetDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveHandoffReservationsFromDigest(_ items: [OrderSetDigest]) -> [HandoffReservation] {
        var out: [HandoffReservation] = []
        for item in items {
            let derived = newHandoffReservation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankHandoffReservation(_ item: HandoffReservation) -> String {
        return normalizeGlobalOrderSetWindowCode(item.code)
    }
}
