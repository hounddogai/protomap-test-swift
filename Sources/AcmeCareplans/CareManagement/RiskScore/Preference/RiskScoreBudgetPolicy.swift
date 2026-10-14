import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRiskScoreBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a risk score budget score falls in.
    static func classifyRiskScoreBudget(_ score: Double) -> String {
        if score < 19.5 {
            return "minimal"
        }
        if score < 62.8 {
            return "elevated"
        }
        if score < 94.5 {
            return "medium"
        }
        return "ok"
    }
}
