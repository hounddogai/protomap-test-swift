import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationDigestsForReservation(_ items: [RevocationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRevocationReservationsFromDigest(_ items: [RevocationDigest]) -> [RevocationReservation] {
        var out: [RevocationReservation] = []
        for item in items {
            let derived = newRevocationReservation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRevocationReservation(_ item: RevocationReservation) -> String {
        return normalizeRevocationMetricCode(item.code)
    }
}
