import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRollupsForSnapshot(_ items: [ClosureRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveNetworkSnapshotsFromRollup(_ items: [ClosureRollup]) -> [AdaptiveNetworkSnapshot] {
        var out: [AdaptiveNetworkSnapshot] = []
        for item in items {
            let derived = newAdaptiveNetworkSnapshot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveAdaptiveNetworkSnapshot(_ item: AdaptiveNetworkSnapshot) -> String {
        return classifyManualClosureReview(item.adjustedVolume())
    }
}
