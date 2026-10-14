import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall rollup code in its canonical RR- form.
    static func normalizeRecallRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func recallRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a recall rollup score falls in.
    static func classifyRecallRollup(_ score: Double) -> String {
        if score < 24.9 {
            return "watch"
        }
        if score < 31.3 {
            return "high"
        }
        return "critical"
    }

    static func recallRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
