import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanReservationsForEstimate(_ items: [AcuityPlanReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveAcuityPlanEstimatesFromReservation(_ items: [AcuityPlanReservation]) -> [AcuityPlanEstimate] {
        var out: [AcuityPlanEstimate] = []
        for item in items {
            let derived = newAcuityPlanEstimate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeAcuityPlanEstimate(_ item: AcuityPlanEstimate) -> String {
        return normalizeAcuityPlanPolicyCode(item.code)
    }
}
