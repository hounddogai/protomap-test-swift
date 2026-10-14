import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalNetworkCyclesForGroup(_ items: [SeasonalNetworkCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveScheduledFollowUpGroupsFromCycle(_ items: [SeasonalNetworkCycle]) -> [ScheduledFollowUpGroup] {
        var out: [ScheduledFollowUpGroup] = []
        for item in items {
            let derived = newScheduledFollowUpGroup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceScheduledFollowUpGroup(_ item: ScheduledFollowUpGroup) -> String {
        return seasonalNetworkCycleBucket(item.weightedVolume())
    }
}
