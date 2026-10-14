import AcmePlatform
import Foundation

extension RevenueCycle {
    static func pendingClaimReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func pendingClaimReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a pending claim reservation score falls in.
    static func classifyPendingClaimReservation(_ score: Double) -> String {
        if score < 6.3 {
            return "ok"
        }
        if score < 24.2 {
            return "watch"
        }
        if score < 77.8 {
            return "elevated"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingClaimReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-claim-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
