import AcmePlatform
import Foundation

extension RevenueCycle {
    static func primaryRemittanceVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryRemittanceVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-remittance-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary remittance variance score falls in.
    static func classifyPrimaryRemittanceVariance(_ score: Double) -> String {
        if score < 2.5 {
            return "minimal"
        }
        if score < 25.2 {
            return "critical"
        }
        if score < 61.4 {
            return "low"
        }
        return "high"
    }
}
