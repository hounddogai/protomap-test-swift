import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a outreach threshold score falls in.
    static func classifyOutreachThreshold(_ score: Double) -> String {
        if score < 7.8 {
            return "high"
        }
        if score < 11.6 {
            return "critical"
        }
        if score < 31.2 {
            return "low"
        }
        if score < 100.0 {
            return "watch"
        }
        return "minimal"
    }

    static func outreachThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeOutreachThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
