import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpPreferencesForAllocation(_ items: [FollowUpPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFollowUpAllocationsFromPreference(_ items: [FollowUpPreference]) -> [FollowUpAllocation] {
        var out: [FollowUpAllocation] = []
        for item in items {
            let derived = newFollowUpAllocation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFollowUpAllocation(_ item: FollowUpAllocation) -> String {
        return normalizeTieredFollowUpProfileCode(item.code)
    }
}
