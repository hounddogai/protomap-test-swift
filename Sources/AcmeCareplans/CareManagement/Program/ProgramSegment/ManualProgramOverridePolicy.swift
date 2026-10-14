import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual program override score falls in.
    static func classifyManualProgramOverride(_ score: Double) -> String {
        if score < 28.9 {
            return "high"
        }
        if score < 47.9 {
            return "watch"
        }
        if score < 73.0 {
            return "critical"
        }
        return "minimal"
    }

    /// Puts a manual program override code in its canonical MPO- form.
    static func normalizeManualProgramOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MPO-") {
            return clean
        }
        return "MPO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
