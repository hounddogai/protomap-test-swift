import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol request code in its canonical CPR- form.
    static func normalizeCareProtocolRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPR-") {
            return clean
        }
        return "CPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a care protocol request score falls in.
    static func classifyCareProtocolRequest(_ score: Double) -> String {
        if score < 43.4 {
            return "low"
        }
        if score < 50.0 {
            return "critical"
        }
        return "high"
    }

    static func careProtocolRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
