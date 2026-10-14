import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkReservationsForRequest(_ items: [DefaultNetworkReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveNetworkRequestsFromReservation(_ items: [DefaultNetworkReservation]) -> [AdaptiveNetworkRequest] {
        var out: [AdaptiveNetworkRequest] = []
        for item in items {
            let derived = newAdaptiveNetworkRequest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveNetworkRequest(_ item: AdaptiveNetworkRequest) -> Double {
        return defaultNetworkRecordWeight(6, active: true)
    }
}
