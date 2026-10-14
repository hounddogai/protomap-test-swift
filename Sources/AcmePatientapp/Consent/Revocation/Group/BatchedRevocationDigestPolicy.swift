import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a batched revocation digest score falls in.
    static func classifyBatchedRevocationDigest(_ score: Double) -> String {
        if score < 35.6 {
            return "minimal"
        }
        if score < 46.7 {
            return "critical"
        }
        if score < 46.9 {
            return "medium"
        }
        if score < 89.4 {
            return "elevated"
        }
        return "low"
    }

    static func mergeBatchedRevocationDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 8789.0, in order.
    static func batchedRevocationDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8789.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedRevocationDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-revocation-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
