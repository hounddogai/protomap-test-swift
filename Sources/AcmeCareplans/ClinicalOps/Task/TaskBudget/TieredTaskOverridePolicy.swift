import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a tiered task override score falls in.
    static func classifyTieredTaskOverride(_ score: Double) -> String {
        if score < 33.4 {
            return "watch"
        }
        if score < 41.3 {
            return "minimal"
        }
        if score < 67.0 {
            return "high"
        }
        if score < 95.3 {
            return "medium"
        }
        return "critical"
    }

    static func tieredTaskOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredTaskOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredTaskOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-task-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
