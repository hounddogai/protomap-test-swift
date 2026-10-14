import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingDenialEntriesForTarget(_ items: [RollingDenialEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveClaimTargetsFromEntry(_ items: [RollingDenialEntry]) -> [ClaimTarget] {
        var out: [ClaimTarget] = []
        for item in items {
            let derived = newClaimTarget(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planClaimTarget(_ item: ClaimTarget) -> String {
        return normalizeRollingDenialEntryCode(item.code)
    }
}
