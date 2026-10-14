import AcmePlatform
import Foundation

extension CareManagement {
    static func seasonalOutreachDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a seasonal outreach digest code in its canonical SOD- form.
    static func normalizeSeasonalOutreachDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOD-") {
            return clean
        }
        return "SOD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalOutreachDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
