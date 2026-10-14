import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a capped overtime rollup score falls in.
    static func classifyCappedOvertimeRollup(_ score: Double) -> String {
        if score < 6.8 {
            return "low"
        }
        if score < 22.9 {
            return "critical"
        }
        if score < 62.3 {
            return "minimal"
        }
        return "high"
    }

    static func cappedOvertimeRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cappedOvertimeRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
