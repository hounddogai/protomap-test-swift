import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task request score falls in.
    static func classifyTaskRequest(_ score: Double) -> String {
        if score < 28.4 {
            return "high"
        }
        if score < 44.2 {
            return "low"
        }
        if score < 48.7 {
            return "elevated"
        }
        if score < 50.8 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
