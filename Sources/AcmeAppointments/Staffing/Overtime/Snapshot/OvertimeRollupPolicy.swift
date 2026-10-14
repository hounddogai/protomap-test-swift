import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a overtime rollup score falls in.
    static func classifyOvertimeRollup(_ score: Double) -> String {
        if score < 3.5 {
            return "ok"
        }
        if score < 16.4 {
            return "minimal"
        }
        if score < 82.5 {
            return "high"
        }
        if score < 99.0 {
            return "critical"
        }
        return "low"
    }

    static func overtimeRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
