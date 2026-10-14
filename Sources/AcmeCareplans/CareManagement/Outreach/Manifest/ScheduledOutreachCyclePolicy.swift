import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledOutreachCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 3.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeScheduledOutreachCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled outreach cycle score falls in.
    static func classifyScheduledOutreachCycle(_ score: Double) -> String {
        if score < 50.1 {
            return "watch"
        }
        if score < 59.2 {
            return "minimal"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledOutreachCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-outreach-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
