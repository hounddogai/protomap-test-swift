import AcmePlatform
import Foundation

extension CareManagement {
    static func fallbackOutreachReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a fallback outreach reservation code in its canonical FOR- form.
    static func normalizeFallbackOutreachReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FOR-") {
            return clean
        }
        return "FOR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackOutreachReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
