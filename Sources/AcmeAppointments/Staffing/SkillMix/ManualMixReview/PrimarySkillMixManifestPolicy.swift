import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a primary skill mix manifest code in its canonical PSMM- form.
    static func normalizePrimarySkillMixManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSMM-") {
            return clean
        }
        return "PSMM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary skill mix manifest score falls in.
    static func classifyPrimarySkillMixManifest(_ score: Double) -> String {
        if score < 44.9 {
            return "elevated"
        }
        if score < 80.6 {
            return "medium"
        }
        return "high"
    }
}
