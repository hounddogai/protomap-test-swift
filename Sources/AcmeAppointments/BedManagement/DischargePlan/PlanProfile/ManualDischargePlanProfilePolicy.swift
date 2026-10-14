import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a manual discharge plan profile score falls in.
    static func classifyManualDischargePlanProfile(_ score: Double) -> String {
        if score < 16.8 {
            return "low"
        }
        if score < 39.2 {
            return "elevated"
        }
        if score < 58.1 {
            return "minimal"
        }
        if score < 67.2 {
            return "ok"
        }
        return "watch"
    }

    static func manualDischargePlanProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a manual discharge plan profile code in its canonical MDPP- form.
    static func normalizeManualDischargePlanProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MDPP-") {
            return clean
        }
        return "MDPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
