import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a scheduled skill mix estimate code in its canonical SSME- form.
    static func normalizeScheduledSkillMixEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSME-") {
            return clean
        }
        return "SSME-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled skill mix estimate score falls in.
    static func classifyScheduledSkillMixEstimate(_ score: Double) -> String {
        if score < 14.3 {
            return "ok"
        }
        if score < 44.6 {
            return "minimal"
        }
        return "critical"
    }
}
