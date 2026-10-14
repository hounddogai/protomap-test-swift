import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalAcuityPlanReservationsForCycle(_ items: [RegionalAcuityPlanReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveSkillMixCyclesFromReservation(_ items: [RegionalAcuityPlanReservation]) -> [SkillMixCycle] {
        var out: [SkillMixCycle] = []
        for item in items {
            let derived = newSkillMixCycle(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateSkillMixCycle(_ item: SkillMixCycle) -> Double {
        return regionalAcuityPlanReservationWeight(5, active: true)
    }
}
