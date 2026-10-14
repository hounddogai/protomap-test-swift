import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotDigestsForManifest(_ items: [SlotDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveNetworkManifestsFromDigest(_ items: [SlotDigest]) -> [NetworkManifest] {
        var out: [NetworkManifest] = []
        for item in items {
            let derived = newNetworkManifest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveNetworkManifest(_ item: NetworkManifest) -> String {
        return classifySlotDigest(item.projectedLoad())
    }
}
