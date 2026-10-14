import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePendingCensusAllocationsForForecast(_ items: [PendingCensusAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveLegacyIsolationForecastsFromAllocation(_ items: [PendingCensusAllocation]) -> [LegacyIsolationForecast] {
        var out: [LegacyIsolationForecast] = []
        for item in items {
            let derived = newLegacyIsolationForecast(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyIsolationForecast(_ item: LegacyIsolationForecast) -> String {
        return defaultCensusReservationBucket(item.adjustedTotal())
    }
}
