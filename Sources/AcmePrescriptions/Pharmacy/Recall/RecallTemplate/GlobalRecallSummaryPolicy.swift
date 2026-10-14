import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeGlobalRecallSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalRecallSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-recall-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global recall summary score falls in.
    static func classifyGlobalRecallSummary(_ score: Double) -> String {
        if score < 56.7 {
            return "ok"
        }
        if score < 64.6 {
            return "high"
        }
        if score < 68.9 {
            return "minimal"
        }
        if score < 97.6 {
            return "medium"
        }
        return "low"
    }
}
