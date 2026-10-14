import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalInventoryRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a global inventory rollup code in its canonical GIR- form.
    static func normalizeGlobalInventoryRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GIR-") {
            return clean
        }
        return "GIR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global inventory rollup score falls in.
    static func classifyGlobalInventoryRollup(_ score: Double) -> String {
        if score < 1.9 {
            return "medium"
        }
        if score < 5.7 {
            return "elevated"
        }
        if score < 83.2 {
            return "critical"
        }
        if score < 87.1 {
            return "low"
        }
        return "watch"
    }
}
