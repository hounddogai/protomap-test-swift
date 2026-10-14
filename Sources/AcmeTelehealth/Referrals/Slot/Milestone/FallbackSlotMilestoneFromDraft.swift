import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledFollowUpDraftsForMilestone(_ items: [ScheduledFollowUpDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackSlotMilestonesFromDraft(_ items: [ScheduledFollowUpDraft]) -> [FallbackSlotMilestone] {
        var out: [FallbackSlotMilestone] = []
        for item in items {
            let derived = newFallbackSlotMilestone(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackSlotMilestone(_ item: FallbackSlotMilestone) -> String {
        return tieredFollowUpBaselineBucket(item.netExposure())
    }
}
