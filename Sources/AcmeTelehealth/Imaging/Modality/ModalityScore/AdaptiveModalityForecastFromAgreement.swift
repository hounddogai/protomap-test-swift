import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualWorklistAgreementsForForecast(_ items: [ManualWorklistAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveModalityForecastsFromAgreement(_ items: [ManualWorklistAgreement]) -> [AdaptiveModalityForecast] {
        var out: [AdaptiveModalityForecast] = []
        for item in items {
            let derived = newAdaptiveModalityForecast(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectAdaptiveModalityForecast(_ item: AdaptiveModalityForecast) -> String {
        return normalizeManualWorklistAgreementCode(item.code)
    }
}
