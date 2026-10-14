import AcmePlatform
import Foundation

extension Consent {
    static func languageQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a language quota score falls in.
    static func classifyLanguageQuota(_ score: Double) -> String {
        if score < 48.0 {
            return "elevated"
        }
        if score < 86.5 {
            return "minimal"
        }
        return "low"
    }

    /// Puts a language quota code in its canonical LQ- form.
    static func normalizeLanguageQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LQ-") {
            return clean
        }
        return "LQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func languageQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
