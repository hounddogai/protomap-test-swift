import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a scheduled program exception score falls in.
    static func classifyScheduledProgramException(_ score: Double) -> String {
        if score < 35.7 {
            return "low"
        }
        if score < 46.6 {
            return "elevated"
        }
        if score < 75.7 {
            return "minimal"
        }
        if score < 91.6 {
            return "critical"
        }
        return "medium"
    }

    /// Puts a scheduled program exception code in its canonical SPE- form.
    static func normalizeScheduledProgramExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPE-") {
            return clean
        }
        return "SPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
