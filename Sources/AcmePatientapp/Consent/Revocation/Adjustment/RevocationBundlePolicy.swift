import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation bundle score falls in.
    static func classifyRevocationBundle(_ score: Double) -> String {
        if score < 3.9 {
            return "watch"
        }
        if score < 26.3 {
            return "medium"
        }
        if score < 89.1 {
            return "elevated"
        }
        return "low"
    }

    static func revocationBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
