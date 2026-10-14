import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedStatementForecastsForLedger(_ items: [CappedStatementForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveChargeLedgersFromForecast(_ items: [CappedStatementForecast]) -> [ChargeLedger] {
        var out: [ChargeLedger] = []
        for item in items {
            let derived = newChargeLedger(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileChargeLedger(_ item: ChargeLedger) -> String {
        return classifyAdaptiveStatementRollup(item.projectedExposure())
    }
}
