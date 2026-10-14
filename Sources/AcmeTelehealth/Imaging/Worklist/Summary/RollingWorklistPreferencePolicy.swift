import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingWorklistPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-worklist-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingWorklistPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling worklist preference score falls in.
    static func classifyRollingWorklistPreference(_ score: Double) -> String {
        if score < 16.8 {
            return "watch"
        }
        if score < 43.8 {
            return "high"
        }
        if score < 65.1 {
            return "ok"
        }
        if score < 83.2 {
            return "critical"
        }
        return "medium"
    }

    static func mergeRollingWorklistPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
