import AcmePlatform
import Foundation

extension Staffing {
    static func credentialRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func credentialRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
