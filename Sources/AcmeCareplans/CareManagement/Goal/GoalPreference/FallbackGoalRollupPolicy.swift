import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a fallback goal rollup score falls in.
    static func classifyFallbackGoalRollup(_ score: Double) -> String {
        if score < 29.2 {
            return "medium"
        }
        if score < 48.0 {
            return "critical"
        }
        if score < 73.2 {
            return "low"
        }
        if score < 95.1 {
            return "ok"
        }
        return "high"
    }

    static func fallbackGoalRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func fallbackGoalRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a fallback goal rollup code in its canonical FGR- form.
    static func normalizeFallbackGoalRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FGR-") {
            return clean
        }
        return "FGR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
