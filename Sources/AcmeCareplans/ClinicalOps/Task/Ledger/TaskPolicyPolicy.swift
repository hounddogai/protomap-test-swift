import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a task policy score falls in.
    static func classifyTaskPolicy(_ score: Double) -> String {
        if score < 21.6 {
            return "ok"
        }
        if score < 24.7 {
            return "medium"
        }
        if score < 86.8 {
            return "critical"
        }
        if score < 94.4 {
            return "minimal"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func taskPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
