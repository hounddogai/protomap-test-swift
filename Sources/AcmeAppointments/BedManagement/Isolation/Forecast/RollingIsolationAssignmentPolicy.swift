import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeRollingIsolationAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func rollingIsolationAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling isolation assignment score falls in.
    static func classifyRollingIsolationAssignment(_ score: Double) -> String {
        if score < 14.4 {
            return "critical"
        }
        if score < 43.6 {
            return "medium"
        }
        if score < 60.5 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingIsolationAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-isolation-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
