import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingPanelPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-panel-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingPanelPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a rolling panel plan score falls in.
    static func classifyRollingPanelPlan(_ score: Double) -> String {
        if score < 7.9 {
            return "watch"
        }
        if score < 47.9 {
            return "medium"
        }
        return "high"
    }

    static func rollingPanelPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
