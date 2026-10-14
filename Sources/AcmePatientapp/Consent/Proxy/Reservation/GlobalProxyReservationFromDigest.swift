import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveWitnessDigestsForReservation(_ items: [AdaptiveWitnessDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalProxyReservationsFromDigest(_ items: [AdaptiveWitnessDigest]) -> [GlobalProxyReservation] {
        var out: [GlobalProxyReservation] = []
        for item in items {
            let derived = newGlobalProxyReservation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankGlobalProxyReservation(_ item: GlobalProxyReservation) -> Double {
        return regionalWitnessBatchWeight(2, active: true)
    }
}
