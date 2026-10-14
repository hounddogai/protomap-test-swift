import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledLanguageExceptionsForForecast(_ items: [ScheduledLanguageException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictLanguageForecastsFromException(_ items: [ScheduledLanguageException]) -> [StrictLanguageForecast] {
        var out: [StrictLanguageForecast] = []
        for item in items {
            let derived = newStrictLanguageForecast(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileStrictLanguageForecast(_ item: StrictLanguageForecast) -> String {
        return normalizeLanguageTargetCode(item.code)
    }
}
