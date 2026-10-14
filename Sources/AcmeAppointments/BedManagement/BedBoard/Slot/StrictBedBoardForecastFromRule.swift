import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledBedBoardRulesForForecast(_ items: [ScheduledBedBoardRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveStrictBedBoardForecastsFromRule(_ items: [ScheduledBedBoardRule]) -> [StrictBedBoardForecast] {
        var out: [StrictBedBoardForecast] = []
        for item in items {
            let derived = newStrictBedBoardForecast(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyStrictBedBoardForecast(_ item: StrictBedBoardForecast) -> Double {
        return cappedBedBoardReservationWeight(7, active: true)
    }
}
