import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyVariancesForPreference(_ items: [StrictProxyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveDisclosurePreferencesFromVariance(_ items: [StrictProxyVariance]) -> [DisclosurePreference] {
        var out: [DisclosurePreference] = []
        for item in items {
            let derived = newDisclosurePreference(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planDisclosurePreference(_ item: DisclosurePreference) -> Double {
        return strictProxyVarianceWeight(5, active: true)
    }
}
