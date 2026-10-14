import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning claim score falls in.
    static func classifyCleaningClaim(_ score: Double) -> String {
        if score < 32.4 {
            return "critical"
        }
        if score < 42.0 {
            return "high"
        }
        if score < 56.9 {
            return "elevated"
        }
        if score < 80.9 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
