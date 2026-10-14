import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning exception score falls in.
    static func classifyCleaningException(_ score: Double) -> String {
        if score < 4.4 {
            return "watch"
        }
        if score < 15.6 {
            return "elevated"
        }
        if score < 34.3 {
            return "low"
        }
        if score < 84.3 {
            return "medium"
        }
        return "ok"
    }

    static func cleaningExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningException() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
