import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyIsolationForecastsForMilestone(_ items: [LegacyIsolationForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveScheduledCensusMilestonesFromForecast(_ items: [LegacyIsolationForecast]) -> [ScheduledCensusMilestone] {
        var out: [ScheduledCensusMilestone] = []
        for item in items {
            let derived = newScheduledCensusMilestone(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectScheduledCensusMilestone(_ item: ScheduledCensusMilestone) -> String {
        return isolationWindowBucket(item.weightedValue())
    }
}
