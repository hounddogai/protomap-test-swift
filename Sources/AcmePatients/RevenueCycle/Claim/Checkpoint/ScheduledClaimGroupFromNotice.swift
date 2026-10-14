import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimNoticesForGroup(_ items: [ClaimNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveScheduledClaimGroupsFromNotice(_ items: [ClaimNotice]) -> [ScheduledClaimGroup] {
        var out: [ScheduledClaimGroup] = []
        for item in items {
            let derived = newScheduledClaimGroup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankScheduledClaimGroup(_ item: ScheduledClaimGroup) -> Double {
        return globalClaimBundleWeight(7, active: true)
    }
}
