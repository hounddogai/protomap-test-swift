import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistSchedulesForAudit(_ items: [WorklistSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingCareProtocolAuditsFromSchedule(_ items: [WorklistSchedule]) -> [RollingCareProtocolAudit] {
        var out: [RollingCareProtocolAudit] = []
        for item in items {
            let derived = newRollingCareProtocolAudit(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRollingCareProtocolAudit(_ item: RollingCareProtocolAudit) -> Double {
        return rollingWorklistScheduleWeight(2, active: true)
    }
}
