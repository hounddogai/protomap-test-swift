import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingRiskScoreRulesForForecast(_ items: [RollingRiskScoreRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCareGapForecastsFromRule(_ items: [RollingRiskScoreRule]) -> [CareGapForecast] {
        var out: [CareGapForecast] = []
        for item in items {
            let derived = newCareGapForecast(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCareGapForecast(_ item: CareGapForecast) -> String {
        return scheduledRiskScoreLedgerBucket(item.adjustedTotal())
    }
}
