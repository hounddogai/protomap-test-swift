import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 82947.0, in order.
    static func rollingAccessionScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82947.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRollingAccessionScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingAccessionScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-accession-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling accession score score falls in.
    static func classifyRollingAccessionScore(_ score: Double) -> String {
        if score < 73.3 {
            return "watch"
        }
        if score < 84.1 {
            return "high"
        }
        if score < 92.6 {
            return "ok"
        }
        if score < 94.5 {
            return "minimal"
        }
        return "low"
    }
}
