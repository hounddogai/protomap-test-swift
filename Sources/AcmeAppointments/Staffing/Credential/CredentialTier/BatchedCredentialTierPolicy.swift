import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedCredentialTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-credential-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedCredentialTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func batchedCredentialTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a batched credential tier score falls in.
    static func classifyBatchedCredentialTier(_ score: Double) -> String {
        if score < 45.1 {
            return "medium"
        }
        if score < 70.7 {
            return "elevated"
        }
        return "ok"
    }
}
