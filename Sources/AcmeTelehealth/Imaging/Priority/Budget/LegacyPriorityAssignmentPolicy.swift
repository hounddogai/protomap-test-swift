import AcmePlatform
import Foundation

extension Imaging {
    static func legacyPriorityAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a legacy priority assignment score falls in.
    static func classifyLegacyPriorityAssignment(_ score: Double) -> String {
        if score < 17.7 {
            return "high"
        }
        if score < 37.6 {
            return "ok"
        }
        return "critical"
    }

    static func legacyPriorityAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
