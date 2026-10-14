import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted recall bundle code in its canonical WRB- form.
    static func normalizeWeightedRecallBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRB-") {
            return clean
        }
        return "WRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedRecallBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a weighted recall bundle score falls in.
    static func classifyWeightedRecallBundle(_ score: Double) -> String {
        if score < 35.2 {
            return "elevated"
        }
        if score < 38.5 {
            return "high"
        }
        return "critical"
    }

    static func weightedRecallBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
