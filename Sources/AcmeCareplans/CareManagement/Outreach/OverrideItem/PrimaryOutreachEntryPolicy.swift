import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryOutreachEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a primary outreach entry code in its canonical POE- form.
    static func normalizePrimaryOutreachEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POE-") {
            return clean
        }
        return "POE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary outreach entry score falls in.
    static func classifyPrimaryOutreachEntry(_ score: Double) -> String {
        if score < 26.2 {
            return "elevated"
        }
        if score < 57.5 {
            return "watch"
        }
        return "low"
    }
}
