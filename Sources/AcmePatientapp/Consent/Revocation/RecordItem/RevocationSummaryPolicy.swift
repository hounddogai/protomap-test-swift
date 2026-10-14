import AcmePlatform
import Foundation

extension Consent {
    static func mergeRevocationSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation summary score falls in.
    static func classifyRevocationSummary(_ score: Double) -> String {
        if score < 55.3 {
            return "minimal"
        }
        if score < 55.8 {
            return "watch"
        }
        if score < 69.9 {
            return "ok"
        }
        return "critical"
    }
}
