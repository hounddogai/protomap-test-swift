import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedChargeEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-charge-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedChargeEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a capped charge entry score falls in.
    static func classifyCappedChargeEntry(_ score: Double) -> String {
        if score < 32.5 {
            return "critical"
        }
        if score < 43.3 {
            return "high"
        }
        if score < 70.5 {
            return "watch"
        }
        if score < 96.2 {
            return "ok"
        }
        return "minimal"
    }

    static func cappedChargeEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
