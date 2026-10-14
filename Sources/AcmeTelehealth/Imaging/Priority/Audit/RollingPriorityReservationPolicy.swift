import AcmePlatform
import Foundation

extension Imaging {
    static func rollingPriorityReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a rolling priority reservation code in its canonical RPR- form.
    static func normalizeRollingPriorityReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPR-") {
            return clean
        }
        return "RPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
