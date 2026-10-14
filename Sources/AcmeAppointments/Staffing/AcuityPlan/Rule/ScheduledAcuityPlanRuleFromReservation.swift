import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftReservationsForRule(_ items: [ShiftReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveScheduledAcuityPlanRulesFromReservation(_ items: [ShiftReservation]) -> [ScheduledAcuityPlanRule] {
        var out: [ScheduledAcuityPlanRule] = []
        for item in items {
            let derived = newScheduledAcuityPlanRule(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeScheduledAcuityPlanRule(_ item: ScheduledAcuityPlanRule) -> String {
        return normalizeGlobalShiftAllocationCode(item.code)
    }
}
