import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict language forecast code in its canonical SLF- form.
    static func normalizeStrictLanguageForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SLF-") {
            return clean
        }
        return "SLF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict language forecast score falls in.
    static func classifyStrictLanguageForecast(_ score: Double) -> String {
        if score < 3.7 {
            return "minimal"
        }
        if score < 85.8 {
            return "high"
        }
        if score < 94.7 {
            return "low"
        }
        return "medium"
    }
}
