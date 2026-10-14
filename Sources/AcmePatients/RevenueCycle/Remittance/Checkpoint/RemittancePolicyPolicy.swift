import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittancePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a remittance policy score falls in.
    static func classifyRemittancePolicy(_ score: Double) -> String {
        if score < 8.8 {
            return "minimal"
        }
        if score < 33.9 {
            return "critical"
        }
        if score < 35.3 {
            return "elevated"
        }
        if score < 53.9 {
            return "ok"
        }
        return "low"
    }
}
