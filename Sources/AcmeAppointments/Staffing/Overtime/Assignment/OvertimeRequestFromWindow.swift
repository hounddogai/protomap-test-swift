import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledAcuityPlanWindowsForRequest(_ items: [ScheduledAcuityPlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOvertimeRequestsFromWindow(_ items: [ScheduledAcuityPlanWindow]) -> [OvertimeRequest] {
        var out: [OvertimeRequest] = []
        for item in items {
            let derived = newOvertimeRequest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }
}
