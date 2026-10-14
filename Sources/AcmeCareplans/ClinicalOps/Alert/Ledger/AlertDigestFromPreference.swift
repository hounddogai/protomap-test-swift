import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertPreferencesForDigest(_ items: [AlertPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAlertDigestsFromPreference(_ items: [AlertPreference]) -> [AlertDigest] {
        var out: [AlertDigest] = []
        for item in items {
            let derived = newAlertDigest(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignAlertDigest(_ item: AlertDigest) -> String {
        return normalizeAlertPreferenceCode(item.code)
    }
}
