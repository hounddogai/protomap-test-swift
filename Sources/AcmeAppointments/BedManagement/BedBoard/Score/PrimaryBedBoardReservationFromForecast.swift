import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyCleaningForecastsForReservation(_ items: [LegacyCleaningForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePrimaryBedBoardReservationsFromForecast(_ items: [LegacyCleaningForecast]) -> [PrimaryBedBoardReservation] {
        var out: [PrimaryBedBoardReservation] = []
        for item in items {
            let derived = newPrimaryBedBoardReservation(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePrimaryBedBoardReservation(_ item: PrimaryBedBoardReservation) -> String {
        return normalizeLegacyCleaningForecastCode(item.code)
    }
}
