import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a global alert forecast code in its canonical GAF- form.
    static func normalizeGlobalAlertForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GAF-") {
            return clean
        }
        return "GAF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalAlertForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a global alert forecast score falls in.
    static func classifyGlobalAlertForecast(_ score: Double) -> String {
        if score < 1.3 {
            return "minimal"
        }
        if score < 11.9 {
            return "elevated"
        }
        if score < 17.9 {
            return "medium"
        }
        return "critical"
    }
}
