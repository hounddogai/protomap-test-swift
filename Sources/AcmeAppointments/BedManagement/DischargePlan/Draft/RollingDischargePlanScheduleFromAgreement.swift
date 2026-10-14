import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictDischargePlanAgreementsForSchedule(_ items: [StrictDischargePlanAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingDischargePlanSchedulesFromAgreement(_ items: [StrictDischargePlanAgreement]) -> [RollingDischargePlanSchedule] {
        var out: [RollingDischargePlanSchedule] = []
        for item in items {
            let derived = newRollingDischargePlanSchedule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingDischargePlanScheduleExtra(_ item: RollingDischargePlanSchedule) -> Double {
        return dischargePlanScheduleWeight(9, active: true)
    }
}
