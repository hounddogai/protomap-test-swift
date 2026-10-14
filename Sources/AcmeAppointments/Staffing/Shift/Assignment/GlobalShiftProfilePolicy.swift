import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a global shift profile score falls in.
    static func classifyGlobalShiftProfile(_ score: Double) -> String {
        if score < 59.3 {
            return "medium"
        }
        if score < 80.8 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalShiftProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-shift-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalShiftProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
