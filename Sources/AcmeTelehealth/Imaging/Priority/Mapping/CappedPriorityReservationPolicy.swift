import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a capped priority reservation code in its canonical CPR- form.
    static func normalizeCappedPriorityReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPR-") {
            return clean
        }
        return "CPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedPriorityReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
