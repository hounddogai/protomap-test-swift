import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralEntriesForCheckpoint(_ items: [ReferralEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveNetworkCheckpointsFromEntry(_ items: [ReferralEntry]) -> [NetworkCheckpoint] {
        var out: [NetworkCheckpoint] = []
        for item in items {
            let derived = newNetworkCheckpoint(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileNetworkCheckpoint(_ item: NetworkCheckpoint) -> String {
        return classifyReferralEntry(item.netLoad())
    }
}
