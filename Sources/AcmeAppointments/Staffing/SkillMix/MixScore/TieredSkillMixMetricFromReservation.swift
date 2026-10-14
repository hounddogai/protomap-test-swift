import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanReservationsForMetric(_ items: [AcuityPlanReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTieredSkillMixMetricsFromReservation(_ items: [AcuityPlanReservation]) -> [TieredSkillMixMetric] {
        var out: [TieredSkillMixMetric] = []
        for item in items {
            let derived = newTieredSkillMixMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeTieredSkillMixMetric(_ item: TieredSkillMixMetric) -> Double {
        return acuityPlanPolicyWeight(6, active: true)
    }
}
