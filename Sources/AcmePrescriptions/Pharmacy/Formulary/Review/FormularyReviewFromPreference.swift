import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalFormularyPreferencesForReview(_ items: [GlobalFormularyPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveFormularyReviewsFromPreference(_ items: [GlobalFormularyPreference]) -> [FormularyReview] {
        var out: [FormularyReview] = []
        for item in items {
            let derived = newFormularyReview(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planFormularyReview(_ item: FormularyReview) -> String {
        return normalizeGlobalFormularyPreferenceCode(item.code)
    }
}
