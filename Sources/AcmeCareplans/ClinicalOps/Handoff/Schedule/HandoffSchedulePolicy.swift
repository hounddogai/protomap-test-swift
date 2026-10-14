import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a handoff schedule score falls in.
    static func classifyHandoffSchedule(_ score: Double) -> String {
        if score < 7.0 {
            return "low"
        }
        if score < 54.6 {
            return "critical"
        }
        if score < 84.1 {
            return "watch"
        }
        if score < 95.9 {
            return "ok"
        }
        return "medium"
    }

    /// Puts a handoff schedule code in its canonical HS- form.
    static func normalizeHandoffScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HS-") {
            return clean
        }
        return "HS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
