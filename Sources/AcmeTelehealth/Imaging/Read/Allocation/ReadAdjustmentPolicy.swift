import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a read adjustment score falls in.
    static func classifyReadAdjustment(_ score: Double) -> String {
        if score < 7.3 {
            return "watch"
        }
        if score < 8.7 {
            return "medium"
        }
        if score < 14.2 {
            return "low"
        }
        if score < 86.7 {
            return "high"
        }
        return "elevated"
    }

    static func readAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a read adjustment code in its canonical RA- form.
    static func normalizeReadAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func readAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
