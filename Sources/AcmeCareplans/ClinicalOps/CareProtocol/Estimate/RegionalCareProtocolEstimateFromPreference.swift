import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertPreferencesForEstimate(_ items: [AlertPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRegionalCareProtocolEstimatesFromPreference(_ items: [AlertPreference]) -> [RegionalCareProtocolEstimate] {
        var out: [RegionalCareProtocolEstimate] = []
        for item in items {
            let derived = newRegionalCareProtocolEstimate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRegionalCareProtocolEstimate(_ item: RegionalCareProtocolEstimate) -> String {
        return normalizeAlertPreferenceCode(item.code)
    }
}
