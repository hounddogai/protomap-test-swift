import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanPreferencesForReservation(_ items: [AcuityPlanPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalAcuityPlanReservationsFromPreference(_ items: [AcuityPlanPreference]) -> [RegionalAcuityPlanReservation] {
        var out: [RegionalAcuityPlanReservation] = []
        for item in items {
            let derived = newRegionalAcuityPlanReservation(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalAcuityPlanReservation(_ item: RegionalAcuityPlanReservation) -> String {
        return acuityPlanPreferenceBucket(item.projectedVolume())
    }
}
