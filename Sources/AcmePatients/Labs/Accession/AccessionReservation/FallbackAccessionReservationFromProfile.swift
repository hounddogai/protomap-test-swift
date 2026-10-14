import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackPanelProfilesForReservation(_ items: [FallbackPanelProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveFallbackAccessionReservationsFromProfile(_ items: [FallbackPanelProfile]) -> [FallbackAccessionReservation] {
        var out: [FallbackAccessionReservation] = []
        for item in items {
            let derived = newFallbackAccessionReservation(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackAccessionReservation(_ item: FallbackAccessionReservation) -> String {
        return classifyRegionalPanelDigest(item.netVolume())
    }
}
