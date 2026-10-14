import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rounding milestone score falls in.
    static func classifyRoundingMilestone(_ score: Double) -> String {
        if score < 12.6 {
            return "low"
        }
        if score < 32.1 {
            return "high"
        }
        return "ok"
    }

    static func mergeRoundingMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
