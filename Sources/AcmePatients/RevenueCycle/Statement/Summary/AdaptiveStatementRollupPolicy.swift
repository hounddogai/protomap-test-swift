import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a adaptive statement rollup code in its canonical ASR- form.
    static func normalizeAdaptiveStatementRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASR-") {
            return clean
        }
        return "ASR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveStatementRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func adaptiveStatementRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive statement rollup score falls in.
    static func classifyAdaptiveStatementRollup(_ score: Double) -> String {
        if score < 25.7 {
            return "elevated"
        }
        if score < 60.4 {
            return "critical"
        }
        if score < 61.4 {
            return "high"
        }
        return "low"
    }
}
