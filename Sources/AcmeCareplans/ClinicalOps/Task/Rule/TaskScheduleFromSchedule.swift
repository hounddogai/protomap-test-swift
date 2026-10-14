import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffSchedulesForSchedule(_ items: [HandoffSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTaskSchedulesFromSchedule(_ items: [HandoffSchedule]) -> [TaskSchedule] {
        var out: [TaskSchedule] = []
        for item in items {
            let derived = newTaskSchedule(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyTaskSchedule(_ item: TaskSchedule) -> Double {
        return handoffGroupWeight(6, active: true)
    }
}
