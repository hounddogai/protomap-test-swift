import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan score score falls in.
    static func classifyAcuityPlanScore(_ score: Double) -> String {
        if score < 22.4 {
            return "medium"
        }
        if score < 33.5 {
            return "ok"
        }
        if score < 36.9 {
            return "critical"
        }
        if score < 79.3 {
            return "watch"
        }
        return "low"
    }

    static func mergeAcuityPlanScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func acuityPlanScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
