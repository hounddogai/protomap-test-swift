import AcmePlatform
import Foundation

extension Labs {
    static func scheduledAccessionMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a scheduled accession milestone code in its canonical SAM- form.
    static func normalizeScheduledAccessionMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAM-") {
            return clean
        }
        return "SAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
