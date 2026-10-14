import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingEstimatesForForecast(_ items: [RoundingEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRollingAlertForecastsFromEstimate(_ items: [RoundingEstimate]) -> [RollingAlertForecast] {
        var out: [RollingAlertForecast] = []
        for item in items {
            let derived = newRollingAlertForecast(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRollingAlertForecast(_ item: RollingAlertForecast) -> Double {
        return lenientRoundingSnapshotWeight(4, active: true)
    }
}
