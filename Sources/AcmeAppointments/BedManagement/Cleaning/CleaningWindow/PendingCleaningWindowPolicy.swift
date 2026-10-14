import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a pending cleaning window score falls in.
    static func classifyPendingCleaningWindow(_ score: Double) -> String {
        if score < 18.2 {
            return "elevated"
        }
        if score < 19.8 {
            return "high"
        }
        if score < 44.9 {
            return "watch"
        }
        if score < 84.2 {
            return "low"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingCleaningWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-cleaning-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePendingCleaningWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingCleaningWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
