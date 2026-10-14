import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryShiftWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-shift-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary shift window score falls in.
    static func classifyPrimaryShiftWindow(_ score: Double) -> String {
        if score < 1.0 {
            return "medium"
        }
        if score < 12.8 {
            return "ok"
        }
        if score < 49.3 {
            return "watch"
        }
        return "critical"
    }
}
