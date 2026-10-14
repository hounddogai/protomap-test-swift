import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a regional interaction forecast code in its canonical RIF- form.
    static func normalizeRegionalInteractionForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RIF-") {
            return clean
        }
        return "RIF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional interaction forecast score falls in.
    static func classifyRegionalInteractionForecast(_ score: Double) -> String {
        if score < 41.5 {
            return "watch"
        }
        if score < 61.9 {
            return "minimal"
        }
        if score < 65.6 {
            return "ok"
        }
        if score < 89.2 {
            return "high"
        }
        return "elevated"
    }
}
