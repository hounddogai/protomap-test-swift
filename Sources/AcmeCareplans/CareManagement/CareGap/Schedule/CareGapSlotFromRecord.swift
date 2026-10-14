import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalRecordsForSlot(_ items: [GoalRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareGapSlotsFromRecord(_ items: [GoalRecord]) -> [CareGapSlot] {
        var out: [CareGapSlot] = []
        for item in items {
            let derived = newCareGapSlot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCareGapSlot(_ item: CareGapSlot) -> String {
        return classifyRollingGoalPolicy(item.adjustedLoad())
    }
}
