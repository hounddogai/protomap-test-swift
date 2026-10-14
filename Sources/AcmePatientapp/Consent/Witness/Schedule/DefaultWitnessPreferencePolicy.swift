import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 32939.0, in order.
    static func defaultWitnessPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32939.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a default witness preference code in its canonical DWP- form.
    static func normalizeDefaultWitnessPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DWP-") {
            return clean
        }
        return "DWP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDefaultWitnessPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default witness preference score falls in.
    static func classifyDefaultWitnessPreference(_ score: Double) -> String {
        if score < 64.0 {
            return "elevated"
        }
        if score < 64.3 {
            return "ok"
        }
        if score < 84.6 {
            return "low"
        }
        if score < 98.1 {
            return "medium"
        }
        return "minimal"
    }
}
