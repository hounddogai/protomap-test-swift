import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotTargetsForSchedule(_ items: [SlotTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFollowUpSchedulesFromTarget(_ items: [SlotTarget]) -> [FollowUpSchedule] {
        var out: [FollowUpSchedule] = []
        for item in items {
            let derived = newFollowUpSchedule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyFollowUpScheduleExtra(_ item: FollowUpSchedule) -> Double {
        return slotTargetWeight(9, active: true)
    }
}
