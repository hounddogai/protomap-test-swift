import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimarySlotSummariesForWindow(_ items: [PrimarySlotSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveDefaultNetworkWindowsFromSummary(_ items: [PrimarySlotSummary]) -> [DefaultNetworkWindow] {
        var out: [DefaultNetworkWindow] = []
        for item in items {
            let derived = newDefaultNetworkWindow(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDefaultNetworkWindow(_ item: DefaultNetworkWindow) -> Double {
        return slotReviewWeight(7, active: true)
    }
}
