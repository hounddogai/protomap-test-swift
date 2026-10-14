import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a strict witness assignment score falls in.
    static func classifyStrictWitnessAssignment(_ score: Double) -> String {
        if score < 40.3 {
            return "ok"
        }
        if score < 63.8 {
            return "watch"
        }
        if score < 97.7 {
            return "critical"
        }
        if score < 100.0 {
            return "high"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictWitnessAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-witness-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictWitnessAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
