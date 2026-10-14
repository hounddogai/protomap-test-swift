import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding baseline score falls in.
    static func classifyRoundingBaseline(_ score: Double) -> String {
        if score < 7.0 {
            return "critical"
        }
        if score < 71.6 {
            return "minimal"
        }
        return "low"
    }

    /// Puts a rounding baseline code in its canonical RB- form.
    static func normalizeRoundingBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
