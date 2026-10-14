import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveStudySchedulesForSchedule(_ items: [AdaptiveStudySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveScheduledPrioritySchedulesFromSchedule(_ items: [AdaptiveStudySchedule]) -> [ScheduledPrioritySchedule] {
        var out: [ScheduledPrioritySchedule] = []
        for item in items {
            let derived = newScheduledPrioritySchedule(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledPrioritySchedule(_ item: ScheduledPrioritySchedule) -> Double {
        return adaptiveStudyScheduleWeight(6, active: true)
    }
}
