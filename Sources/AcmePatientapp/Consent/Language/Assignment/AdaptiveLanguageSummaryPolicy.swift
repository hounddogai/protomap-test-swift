import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveLanguageSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func adaptiveLanguageSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a adaptive language summary code in its canonical ALS- form.
    static func normalizeAdaptiveLanguageSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ALS-") {
            return clean
        }
        return "ALS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
