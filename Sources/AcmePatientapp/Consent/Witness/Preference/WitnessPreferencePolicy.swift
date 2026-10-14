import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 61578.0, in order.
    static func witnessPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61578.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a witness preference score falls in.
    static func classifyWitnessPreference(_ score: Double) -> String {
        if score < 58.5 {
            return "low"
        }
        if score < 61.0 {
            return "watch"
        }
        return "critical"
    }

    static func witnessPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a witness preference code in its canonical WP- form.
    static func normalizeWitnessPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WP-") {
            return clean
        }
        return "WP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
