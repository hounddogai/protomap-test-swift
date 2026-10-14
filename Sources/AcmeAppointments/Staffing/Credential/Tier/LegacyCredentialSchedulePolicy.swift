import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a legacy credential schedule score falls in.
    static func classifyLegacyCredentialSchedule(_ score: Double) -> String {
        if score < 21.6 {
            return "medium"
        }
        if score < 58.1 {
            return "minimal"
        }
        if score < 77.5 {
            return "elevated"
        }
        if score < 91.8 {
            return "low"
        }
        return "high"
    }

    /// Puts a legacy credential schedule code in its canonical LCS- form.
    static func normalizeLegacyCredentialScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCS-") {
            return clean
        }
        return "LCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
