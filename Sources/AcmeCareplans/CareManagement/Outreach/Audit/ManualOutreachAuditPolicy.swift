import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a manual outreach audit code in its canonical MOA- form.
    static func normalizeManualOutreachAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MOA-") {
            return clean
        }
        return "MOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a manual outreach audit score falls in.
    static func classifyManualOutreachAudit(_ score: Double) -> String {
        if score < 54.1 {
            return "low"
        }
        if score < 57.9 {
            return "medium"
        }
        if score < 97.5 {
            return "watch"
        }
        return "critical"
    }
}
