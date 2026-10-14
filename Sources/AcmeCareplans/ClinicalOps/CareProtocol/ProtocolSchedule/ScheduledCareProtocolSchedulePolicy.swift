import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a scheduled care protocol schedule score falls in.
    static func classifyScheduledCareProtocolSchedule(_ score: Double) -> String {
        if score < 6.3 {
            return "medium"
        }
        if score < 9.5 {
            return "ok"
        }
        if score < 30.2 {
            return "high"
        }
        return "low"
    }

    /// Puts a scheduled care protocol schedule code in its canonical SCPS- form.
    static func normalizeScheduledCareProtocolScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPS-") {
            return clean
        }
        return "SCPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
