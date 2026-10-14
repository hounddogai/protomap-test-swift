import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a weighted task assignment score falls in.
    static func classifyWeightedTaskAssignment(_ score: Double) -> String {
        if score < 9.7 {
            return "minimal"
        }
        if score < 40.5 {
            return "low"
        }
        if score < 52.1 {
            return "high"
        }
        if score < 66.6 {
            return "medium"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedTaskAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-task-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
