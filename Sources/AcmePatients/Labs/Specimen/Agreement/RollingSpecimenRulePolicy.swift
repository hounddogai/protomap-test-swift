import AcmePlatform
import Foundation

extension Labs {
    static func rollingSpecimenRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a rolling specimen rule code in its canonical RSR- form.
    static func normalizeRollingSpecimenRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSR-") {
            return clean
        }
        return "RSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling specimen rule score falls in.
    static func classifyRollingSpecimenRule(_ score: Double) -> String {
        if score < 31.5 {
            return "ok"
        }
        if score < 31.7 {
            return "low"
        }
        if score < 55.1 {
            return "elevated"
        }
        if score < 70.3 {
            return "critical"
        }
        return "high"
    }
}
