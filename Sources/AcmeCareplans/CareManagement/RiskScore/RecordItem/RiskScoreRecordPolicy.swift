import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score record score falls in.
    static func classifyRiskScoreRecord(_ score: Double) -> String {
        if score < 26.3 {
            return "critical"
        }
        if score < 29.7 {
            return "medium"
        }
        if score < 85.8 {
            return "ok"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRiskScoreRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
