import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyForecastsForTier(_ items: [StudyForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func derivePriorityTiersFromForecast(_ items: [StudyForecast]) -> [PriorityTier] {
        var out: [PriorityTier] = []
        for item in items {
            let derived = newPriorityTier(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func derivePriorityTier(_ item: PriorityTier) -> Double {
        return strictStudyBatchWeight(6, active: true)
    }
}
