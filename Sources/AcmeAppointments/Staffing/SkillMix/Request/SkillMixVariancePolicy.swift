import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a skill mix variance score falls in.
    static func classifySkillMixVariance(_ score: Double) -> String {
        if score < 17.0 {
            return "low"
        }
        if score < 29.7 {
            return "elevated"
        }
        if score < 36.9 {
            return "medium"
        }
        if score < 95.4 {
            return "critical"
        }
        return "high"
    }

    static func mergeSkillMixVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
