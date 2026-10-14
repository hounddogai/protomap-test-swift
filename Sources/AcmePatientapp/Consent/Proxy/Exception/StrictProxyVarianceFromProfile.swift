import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageProfilesForVariance(_ items: [LanguageProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictProxyVariancesFromProfile(_ items: [LanguageProfile]) -> [StrictProxyVariance] {
        var out: [StrictProxyVariance] = []
        for item in items {
            let derived = newStrictProxyVariance(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectStrictProxyVariance(_ item: StrictProxyVariance) -> String {
        return normalizeLanguageProfileCode(item.code)
    }
}
