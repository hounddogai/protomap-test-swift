import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 90984.0, in order.
    static func languageEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90984.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a language estimate score falls in.
    static func classifyLanguageEstimate(_ score: Double) -> String {
        if score < 35.4 {
            return "minimal"
        }
        if score < 68.9 {
            return "low"
        }
        if score < 90.3 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a language estimate code in its canonical LE- form.
    static func normalizeLanguageEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LE-") {
            return clean
        }
        return "LE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
