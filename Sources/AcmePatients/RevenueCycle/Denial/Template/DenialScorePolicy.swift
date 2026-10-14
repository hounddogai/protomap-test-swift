import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial score score falls in.
    static func classifyDenialScore(_ score: Double) -> String {
        if score < 26.4 {
            return "minimal"
        }
        if score < 44.1 {
            return "high"
        }
        if score < 59.3 {
            return "watch"
        }
        if score < 67.3 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDenialScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("denial-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeDenialScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
