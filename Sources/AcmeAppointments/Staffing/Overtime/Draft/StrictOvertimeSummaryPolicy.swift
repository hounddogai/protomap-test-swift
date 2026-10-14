import AcmePlatform
import Foundation

extension Staffing {
    static func strictOvertimeSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictOvertimeSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a strict overtime summary score falls in.
    static func classifyStrictOvertimeSummary(_ score: Double) -> String {
        if score < 21.1 {
            return "critical"
        }
        if score < 88.5 {
            return "high"
        }
        if score < 92.9 {
            return "low"
        }
        if score < 95.8 {
            return "watch"
        }
        return "minimal"
    }
}
