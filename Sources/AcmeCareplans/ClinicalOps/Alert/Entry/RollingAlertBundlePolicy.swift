import AcmePlatform
import Foundation

extension ClinicalOps {
    static func rollingAlertBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a rolling alert bundle score falls in.
    static func classifyRollingAlertBundle(_ score: Double) -> String {
        if score < 48.9 {
            return "watch"
        }
        if score < 70.0 {
            return "elevated"
        }
        if score < 89.0 {
            return "high"
        }
        if score < 91.5 {
            return "low"
        }
        return "medium"
    }

    static func rollingAlertBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a rolling alert bundle code in its canonical RAB- form.
    static func normalizeRollingAlertBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAB-") {
            return clean
        }
        return "RAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
