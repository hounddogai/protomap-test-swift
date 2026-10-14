import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackNetworkCheckpointsForBundle(_ items: [FallbackNetworkCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFollowUpBundlesFromCheckpoint(_ items: [FallbackNetworkCheckpoint]) -> [FollowUpBundle] {
        var out: [FollowUpBundle] = []
        for item in items {
            let derived = newFollowUpBundle(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignFollowUpBundle(_ item: FollowUpBundle) -> Double {
        return networkCheckpointWeight(8, active: true)
    }
}
