import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyAuthorizationEntriesForCheckpoint(_ items: [LegacyAuthorizationEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingAuthorizationCheckpointsFromEntry(_ items: [LegacyAuthorizationEntry]) -> [RollingAuthorizationCheckpoint] {
        var out: [RollingAuthorizationCheckpoint] = []
        for item in items {
            let derived = newRollingAuthorizationCheckpoint(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRollingAuthorizationCheckpoint(_ item: RollingAuthorizationCheckpoint) -> String {
        return normalizeWeightedAuthorizationEstimateCode(item.code)
    }
}
