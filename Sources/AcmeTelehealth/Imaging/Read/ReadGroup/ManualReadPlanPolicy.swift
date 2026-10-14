import AcmePlatform
import Foundation

extension Imaging {
    static func mergeManualReadPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualReadPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-read-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualReadPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual read plan score falls in.
    static func classifyManualReadPlan(_ score: Double) -> String {
        if score < 38.9 {
            return "high"
        }
        if score < 76.2 {
            return "low"
        }
        return "medium"
    }
}
