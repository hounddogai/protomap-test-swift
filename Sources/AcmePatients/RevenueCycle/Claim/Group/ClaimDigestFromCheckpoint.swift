import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialCheckpointsForDigest(_ items: [DenialCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveClaimDigestsFromCheckpoint(_ items: [DenialCheckpoint]) -> [ClaimDigest] {
        var out: [ClaimDigest] = []
        for item in items {
            let derived = newClaimDigest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeClaimDigest(_ item: ClaimDigest) -> String {
        return classifyDenialCheckpoint(item.projectedValue())
    }
}
