import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a credential schedule code in its canonical CS- form.
    static func normalizeCredentialScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a credential schedule score falls in.
    static func classifyCredentialSchedule(_ score: Double) -> String {
        if score < 90.8 {
            return "medium"
        }
        if score < 98.4 {
            return "ok"
        }
        return "critical"
    }
}
