import AcmePlatform
import Foundation

extension Consent {
    /// Puts a regional proxy forecast code in its canonical RPF- form.
    static func normalizeRegionalProxyForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPF-") {
            return clean
        }
        return "RPF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional proxy forecast score falls in.
    static func classifyRegionalProxyForecast(_ score: Double) -> String {
        if score < 58.1 {
            return "critical"
        }
        if score < 58.5 {
            return "minimal"
        }
        if score < 80.9 {
            return "watch"
        }
        if score < 82.5 {
            return "medium"
        }
        return "low"
    }
}
