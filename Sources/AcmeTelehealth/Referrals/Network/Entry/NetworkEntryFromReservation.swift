import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralReservationsForEntry(_ items: [ReferralReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveNetworkEntriesFromReservation(_ items: [ReferralReservation]) -> [NetworkEntry] {
        var out: [NetworkEntry] = []
        for item in items {
            let derived = newNetworkEntry(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveNetworkEntry(_ item: NetworkEntry) -> Double {
        return scheduledReferralMappingWeight(3, active: true)
    }
}
