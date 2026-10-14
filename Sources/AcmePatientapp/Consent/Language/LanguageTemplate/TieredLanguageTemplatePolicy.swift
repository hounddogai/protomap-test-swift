import AcmePlatform
import Foundation

extension Consent {
    /// Puts a tiered language template code in its canonical TLT- form.
    static func normalizeTieredLanguageTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TLT-") {
            return clean
        }
        return "TLT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 99032.0, in order.
    static func tieredLanguageTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99032.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a tiered language template score falls in.
    static func classifyTieredLanguageTemplate(_ score: Double) -> String {
        if score < 43.9 {
            return "watch"
        }
        if score < 50.8 {
            return "critical"
        }
        if score < 97.1 {
            return "minimal"
        }
        return "elevated"
    }
}
