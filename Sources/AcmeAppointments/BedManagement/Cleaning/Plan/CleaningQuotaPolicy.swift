import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a cleaning quota score falls in.
    static func classifyCleaningQuota(_ score: Double) -> String {
        if score < 59.9 {
            return "elevated"
        }
        if score < 78.0 {
            return "low"
        }
        if score < 79.2 {
            return "medium"
        }
        if score < 88.6 {
            return "critical"
        }
        return "minimal"
    }
}
