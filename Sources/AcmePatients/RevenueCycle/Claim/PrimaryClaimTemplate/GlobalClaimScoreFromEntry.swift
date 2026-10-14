import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyAuthorizationEntriesForScore(_ items: [LegacyAuthorizationEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveGlobalClaimScoresFromEntry(_ items: [LegacyAuthorizationEntry]) -> [GlobalClaimScore] {
        var out: [GlobalClaimScore] = []
        for item in items {
            let derived = newGlobalClaimScore(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalClaimScore(_ item: GlobalClaimScore) -> String {
        return legacyAuthorizationEntryBucket(item.effectiveExposure())
    }
}
