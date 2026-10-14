import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualAcuityPlanReservationsForVariance(_ items: [ManualAcuityPlanReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveGlobalShiftVariancesFromReservation(_ items: [ManualAcuityPlanReservation]) -> [GlobalShiftVariance] {
        var out: [GlobalShiftVariance] = []
        for item in items {
            let derived = newGlobalShiftVariance(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateGlobalShiftVariance(_ item: GlobalShiftVariance) -> Double {
        return manualAcuityPlanReservationWeight(8, active: true)
    }
}
