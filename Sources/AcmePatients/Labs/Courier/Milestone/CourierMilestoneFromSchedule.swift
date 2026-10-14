import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultSchedulesForMilestone(_ items: [ResultSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCourierMilestonesFromSchedule(_ items: [ResultSchedule]) -> [CourierMilestone] {
        var out: [CourierMilestone] = []
        for item in items {
            let derived = newCourierMilestone(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCourierMilestone(_ item: CourierMilestone) -> String {
        return classifyResultThreshold(item.adjustedValue())
    }
}
