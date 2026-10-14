import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedStatementGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func batchedStatementGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedStatementGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-statement-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched statement group score falls in.
    static func classifyBatchedStatementGroup(_ score: Double) -> String {
        if score < 13.5 {
            return "elevated"
        }
        if score < 63.0 {
            return "low"
        }
        return "minimal"
    }
}
