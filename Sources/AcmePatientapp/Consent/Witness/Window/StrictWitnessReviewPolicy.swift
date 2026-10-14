import AcmePlatform
import Foundation

extension Consent {
    static func strictWitnessReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func strictWitnessReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a strict witness review code in its canonical SWR- form.
    static func normalizeStrictWitnessReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWR-") {
            return clean
        }
        return "SWR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
