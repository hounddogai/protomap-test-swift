import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalAcuityPlanForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-acuity-plan-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeGlobalAcuityPlanForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalAcuityPlanForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a global acuity plan forecast score falls in.
    static func classifyGlobalAcuityPlanForecast(_ score: Double) -> String {
        if score < 28.9 {
            return "low"
        }
        if score < 37.1 {
            return "watch"
        }
        if score < 90.7 {
            return "elevated"
        }
        if score < 94.2 {
            return "critical"
        }
        return "high"
    }
}
