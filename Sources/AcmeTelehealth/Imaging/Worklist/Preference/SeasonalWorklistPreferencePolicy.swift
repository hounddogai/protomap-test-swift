import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a seasonal worklist preference code in its canonical SWP- form.
    static func normalizeSeasonalWorklistPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWP-") {
            return clean
        }
        return "SWP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal worklist preference score falls in.
    static func classifySeasonalWorklistPreference(_ score: Double) -> String {
        if score < 8.8 {
            return "watch"
        }
        if score < 30.8 {
            return "low"
        }
        if score < 63.8 {
            return "medium"
        }
        return "high"
    }
}
