import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a rolling float pool assignment score falls in.
    static func classifyRollingFloatPoolAssignment(_ score: Double) -> String {
        if score < 14.0 {
            return "high"
        }
        if score < 36.6 {
            return "elevated"
        }
        if score < 48.4 {
            return "minimal"
        }
        return "low"
    }

    static func rollingFloatPoolAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func rollingFloatPoolAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
