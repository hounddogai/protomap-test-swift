import AcmePlatform
import Foundation

extension Imaging {
    static func tieredPriorityReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a tiered priority reservation code in its canonical TPR- form.
    static func normalizeTieredPriorityReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TPR-") {
            return clean
        }
        return "TPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredPriorityReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
