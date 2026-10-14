import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredCareGapAssignmentsForReservation(_ items: [TieredCareGapAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRegionalRiskScoreReservationsFromAssignment(_ items: [TieredCareGapAssignment]) -> [RegionalRiskScoreReservation] {
        var out: [RegionalRiskScoreReservation] = []
        for item in items {
            let derived = newRegionalRiskScoreReservation(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRegionalRiskScoreReservation(_ item: RegionalRiskScoreReservation) -> Double {
        return tieredCareGapAssignmentWeight(8, active: true)
    }
}
