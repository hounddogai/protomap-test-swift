import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalRiskScoreReservationsForAllocation(_ items: [SeasonalRiskScoreReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalCareGapAllocationsFromReservation(_ items: [SeasonalRiskScoreReservation]) -> [GlobalCareGapAllocation] {
        var out: [GlobalCareGapAllocation] = []
        for item in items {
            let derived = newGlobalCareGapAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceGlobalCareGapAllocation(_ item: GlobalCareGapAllocation) -> String {
        return seasonalRiskScoreReservationBucket(item.weightedVolume())
    }
}
