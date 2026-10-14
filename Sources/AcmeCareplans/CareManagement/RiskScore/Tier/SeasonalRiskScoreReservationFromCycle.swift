import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramCyclesForReservation(_ items: [ProgramCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalRiskScoreReservationsFromCycle(_ items: [ProgramCycle]) -> [SeasonalRiskScoreReservation] {
        var out: [SeasonalRiskScoreReservation] = []
        for item in items {
            let derived = newSeasonalRiskScoreReservation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitSeasonalRiskScoreReservation(_ item: SeasonalRiskScoreReservation) -> String {
        return lenientProgramWindowBucket(item.projectedValue())
    }
}
