import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a task estimate score falls in.
    static func classifyTaskEstimate(_ score: Double) -> String {
        if score < 18.9 {
            return "low"
        }
        if score < 38.8 {
            return "watch"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func taskEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
