import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictReferenceRangeRulesForSchedule(_ items: [StrictReferenceRangeRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveCourierSchedulesFromRule(_ items: [StrictReferenceRangeRule]) -> [CourierSchedule] {
        var out: [CourierSchedule] = []
        for item in items {
            let derived = newCourierSchedule(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCourierSchedule(_ item: CourierSchedule) -> Double {
        return fallbackReferenceRangeVarianceWeight(2, active: true)
    }
}
