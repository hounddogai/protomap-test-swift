import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func overtimeMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a overtime milestone code in its canonical OM- form.
    static func normalizeOvertimeMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OM-") {
            return clean
        }
        return "OM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
