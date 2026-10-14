import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance exception score falls in.
    static func classifyRemittanceException(_ score: Double) -> String {
        if score < 15.9 {
            return "critical"
        }
        if score < 17.3 {
            return "ok"
        }
        if score < 45.3 {
            return "high"
        }
        if score < 79.4 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceException() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
