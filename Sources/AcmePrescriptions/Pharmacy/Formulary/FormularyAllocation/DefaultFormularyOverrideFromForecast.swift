import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientInteractionForecastsForOverride(_ items: [LenientInteractionForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultFormularyOverridesFromForecast(_ items: [LenientInteractionForecast]) -> [DefaultFormularyOverride] {
        var out: [DefaultFormularyOverride] = []
        for item in items {
            let derived = newDefaultFormularyOverride(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchDefaultFormularyOverride(_ item: DefaultFormularyOverride) -> String {
        return normalizeLenientInteractionScheduleCode(item.code)
    }
}
