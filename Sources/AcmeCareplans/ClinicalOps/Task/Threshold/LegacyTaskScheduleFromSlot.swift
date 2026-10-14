import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSlotsForSchedule(_ items: [AlertSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLegacyTaskSchedulesFromSlot(_ items: [AlertSlot]) -> [LegacyTaskSchedule] {
        var out: [LegacyTaskSchedule] = []
        for item in items {
            let derived = newLegacyTaskSchedule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLegacyTaskSchedule(_ item: LegacyTaskSchedule) -> Double {
        return alertSlotWeight(9, active: true)
    }
}
