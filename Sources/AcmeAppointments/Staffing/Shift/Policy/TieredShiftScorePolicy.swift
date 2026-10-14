import AcmePlatform
import Foundation

extension Staffing {
    static func mergeTieredShiftScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered shift score score falls in.
    static func classifyTieredShiftScore(_ score: Double) -> String {
        if score < 46.2 {
            return "low"
        }
        if score < 75.5 {
            return "minimal"
        }
        if score < 83.9 {
            return "watch"
        }
        if score < 90.3 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredShiftScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-shift-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
