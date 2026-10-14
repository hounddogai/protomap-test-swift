import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a legacy statement variance score falls in.
    static func classifyLegacyStatementVariance(_ score: Double) -> String {
        if score < 15.2 {
            return "low"
        }
        if score < 15.4 {
            return "elevated"
        }
        if score < 63.1 {
            return "critical"
        }
        return "high"
    }

    static func legacyStatementVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyStatementVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-statement-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyStatementVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
