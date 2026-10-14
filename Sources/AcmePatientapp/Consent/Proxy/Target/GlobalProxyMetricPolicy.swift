import AcmePlatform
import Foundation

extension Consent {
    static func globalProxyMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a global proxy metric code in its canonical GPM- form.
    static func normalizeGlobalProxyMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPM-") {
            return clean
        }
        return "GPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
