import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a default remittance target score falls in.
    static func classifyDefaultRemittanceTarget(_ score: Double) -> String {
        if score < 24.3 {
            return "high"
        }
        if score < 45.0 {
            return "watch"
        }
        if score < 81.5 {
            return "minimal"
        }
        if score < 84.8 {
            return "elevated"
        }
        return "low"
    }

    static func defaultRemittanceTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultRemittanceTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-remittance-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
