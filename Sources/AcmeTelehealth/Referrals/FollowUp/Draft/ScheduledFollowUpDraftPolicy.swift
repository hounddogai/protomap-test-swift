import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a scheduled follow up draft code in its canonical SFUD- form.
    static func normalizeScheduledFollowUpDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUD-") {
            return clean
        }
        return "SFUD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledFollowUpDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
