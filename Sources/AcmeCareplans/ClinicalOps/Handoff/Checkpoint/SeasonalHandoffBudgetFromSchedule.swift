import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledAlertSchedulesForBudget(_ items: [ScheduledAlertSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSeasonalHandoffBudgetsFromSchedule(_ items: [ScheduledAlertSchedule]) -> [SeasonalHandoffBudget] {
        var out: [SeasonalHandoffBudget] = []
        for item in items {
            let derived = newSeasonalHandoffBudget(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitSeasonalHandoffBudget(_ item: SeasonalHandoffBudget) -> String {
        return normalizeRegionalAlertMetricCode(item.code)
    }
}
