import AcmePlatform
import Foundation

extension Pharmacy {
    static func strictInteractionThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func strictInteractionThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a strict interaction threshold code in its canonical SIT- form.
    static func normalizeStrictInteractionThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIT-") {
            return clean
        }
        return "SIT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
