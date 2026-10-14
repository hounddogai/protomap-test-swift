import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyClosureCyclesForReservation(_ items: [LegacyClosureCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveDefaultNetworkReservationsFromCycle(_ items: [LegacyClosureCycle]) -> [DefaultNetworkReservation] {
        var out: [DefaultNetworkReservation] = []
        for item in items {
            let derived = newDefaultNetworkReservation(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultNetworkReservation(_ item: DefaultNetworkReservation) -> String {
        return classifyLegacyClosureCycle(item.measuredValue())
    }
}
