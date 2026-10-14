import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a pending overtime snapshot score falls in.
    static func classifyPendingOvertimeSnapshot(_ score: Double) -> String {
        if score < 13.9 {
            return "ok"
        }
        if score < 32.8 {
            return "elevated"
        }
        if score < 84.6 {
            return "medium"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingOvertimeSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-overtime-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
