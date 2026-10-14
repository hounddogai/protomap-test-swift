import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveFollowUpNoticesForSchedule(_ items: [AdaptiveFollowUpNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSlotSchedulesFromNotice(_ items: [AdaptiveFollowUpNotice]) -> [SlotSchedule] {
        var out: [SlotSchedule] = []
        for item in items {
            let derived = newSlotSchedule(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeSlotSchedule(_ item: SlotSchedule) -> String {
        return classifyLegacyFollowUpAudit(item.projectedVolume())
    }
}
