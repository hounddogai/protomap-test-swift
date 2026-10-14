import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict proxy baseline code in its canonical SPB- form.
    static func normalizeStrictProxyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPB-") {
            return clean
        }
        return "SPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictProxyBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func strictProxyBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
