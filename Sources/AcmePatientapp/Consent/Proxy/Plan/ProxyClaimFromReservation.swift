import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationReservationsForClaim(_ items: [RevocationReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveProxyClaimsFromReservation(_ items: [RevocationReservation]) -> [ProxyClaim] {
        var out: [ProxyClaim] = []
        for item in items {
            let derived = newProxyClaim(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyProxyClaim(_ item: ProxyClaim) -> Double {
        return revocationExceptionWeight(9, active: true)
    }
}
