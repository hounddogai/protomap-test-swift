import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a lenient risk score preference score falls in.
    static func classifyLenientRiskScorePreference(_ score: Double) -> String {
        if score < 27.2 {
            return "minimal"
        }
        if score < 95.9 {
            return "high"
        }
        return "critical"
    }

    static func lenientRiskScorePreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a lenient risk score preference code in its canonical LRSP- form.
    static func normalizeLenientRiskScorePreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRSP-") {
            return clean
        }
        return "LRSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
