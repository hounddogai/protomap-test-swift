import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingDischargePlanScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-discharge-plan-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingDischargePlanScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling discharge plan score score falls in.
    static func classifyRollingDischargePlanScore(_ score: Double) -> String {
        if score < 32.7 {
            return "low"
        }
        if score < 38.3 {
            return "ok"
        }
        if score < 46.7 {
            return "elevated"
        }
        if score < 69.3 {
            return "minimal"
        }
        return "high"
    }

    static func rollingDischargePlanScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
