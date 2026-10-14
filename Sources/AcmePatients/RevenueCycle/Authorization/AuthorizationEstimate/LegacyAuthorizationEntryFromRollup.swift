import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualAuthorizationRollupsForEntry(_ items: [ManualAuthorizationRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLegacyAuthorizationEntriesFromRollup(_ items: [ManualAuthorizationRollup]) -> [LegacyAuthorizationEntry] {
        var out: [LegacyAuthorizationEntry] = []
        for item in items {
            let derived = newLegacyAuthorizationEntry(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyAuthorizationEntry(_ item: LegacyAuthorizationEntry) -> String {
        return batchedAuthorizationTargetBucket(item.effectiveTotal())
    }
}
