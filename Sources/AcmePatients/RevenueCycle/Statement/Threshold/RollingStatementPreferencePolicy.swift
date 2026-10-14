import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a rolling statement preference score falls in.
    static func classifyRollingStatementPreference(_ score: Double) -> String {
        if score < 35.6 {
            return "critical"
        }
        if score < 60.5 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a rolling statement preference code in its canonical RSP- form.
    static func normalizeRollingStatementPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSP-") {
            return clean
        }
        return "RSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
