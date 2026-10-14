import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityPlansForForecast(_ items: [ModalityPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientReadForecastsFromPlan(_ items: [ModalityPlan]) -> [LenientReadForecast] {
        var out: [LenientReadForecast] = []
        for item in items {
            let derived = newLenientReadForecast(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planLenientReadForecast(_ item: LenientReadForecast) -> Double {
        return modalityPlanWeight(2, active: true)
    }
}
