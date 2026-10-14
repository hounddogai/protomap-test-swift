import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledShiftReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledShiftReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-shift-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled shift reservation score falls in.
    static func classifyScheduledShiftReservation(_ score: Double) -> String {
        if score < 2.7 {
            return "minimal"
        }
        if score < 33.3 {
            return "low"
        }
        if score < 41.5 {
            return "ok"
        }
        return "watch"
    }
}
