import AcmePlatform
import Foundation

extension Imaging {
    static func pendingReadAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a pending read adjustment score falls in.
    static func classifyPendingReadAdjustment(_ score: Double) -> String {
        if score < 9.0 {
            return "elevated"
        }
        if score < 41.7 {
            return "ok"
        }
        if score < 45.4 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingReadAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-read-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
