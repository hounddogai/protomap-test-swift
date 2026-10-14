import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a capped goal segment score falls in.
    static func classifyCappedGoalSegment(_ score: Double) -> String {
        if score < 89.1 {
            return "high"
        }
        if score < 96.2 {
            return "ok"
        }
        if score < 99.3 {
            return "low"
        }
        return "medium"
    }

    static func cappedGoalSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedGoalSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-goal-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedGoalSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
