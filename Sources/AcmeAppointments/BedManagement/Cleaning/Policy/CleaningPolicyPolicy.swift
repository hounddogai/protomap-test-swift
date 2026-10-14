import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning policy score falls in.
    static func classifyCleaningPolicy(_ score: Double) -> String {
        if score < 24.7 {
            return "ok"
        }
        if score < 63.5 {
            return "elevated"
        }
        if score < 78.3 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
