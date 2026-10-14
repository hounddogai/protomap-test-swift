import AcmePlatform
import Foundation

extension Consent {
    static func mergeLanguagePreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a language preference score falls in.
    static func classifyLanguagePreference(_ score: Double) -> String {
        if score < 11.0 {
            return "critical"
        }
        if score < 34.8 {
            return "minimal"
        }
        if score < 35.0 {
            return "ok"
        }
        if score < 81.3 {
            return "medium"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 62381.0, in order.
    static func languagePreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62381.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a language preference code in its canonical LP- form.
    static func normalizeLanguagePreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LP-") {
            return clean
        }
        return "LP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
