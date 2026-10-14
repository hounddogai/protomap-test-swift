import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a rolling goal policy score falls in.
    static func classifyRollingGoalPolicy(_ score: Double) -> String {
        if score < 9.5 {
            return "low"
        }
        if score < 54.0 {
            return "critical"
        }
        if score < 82.6 {
            return "ok"
        }
        if score < 97.2 {
            return "minimal"
        }
        return "medium"
    }

    static func rollingGoalPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func rollingGoalPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
