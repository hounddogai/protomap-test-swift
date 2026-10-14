import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilitySchedulesForMilestone(_ items: [EligibilitySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedClosureMilestonesFromSchedule(_ items: [EligibilitySchedule]) -> [CappedClosureMilestone] {
        var out: [CappedClosureMilestone] = []
        for item in items {
            let derived = newCappedClosureMilestone(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedClosureMilestone(_ item: CappedClosureMilestone) -> String {
        return normalizeEligibilityScheduleCode(item.code)
    }
}
