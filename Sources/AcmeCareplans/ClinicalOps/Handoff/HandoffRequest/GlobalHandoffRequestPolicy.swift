import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a global handoff request score falls in.
    static func classifyGlobalHandoffRequest(_ score: Double) -> String {
        if score < 1.5 {
            return "medium"
        }
        if score < 4.1 {
            return "high"
        }
        if score < 8.2 {
            return "critical"
        }
        if score < 39.2 {
            return "watch"
        }
        return "low"
    }

    static func globalHandoffRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func globalHandoffRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
