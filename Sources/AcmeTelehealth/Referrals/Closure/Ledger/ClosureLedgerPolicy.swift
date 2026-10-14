import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClosureLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("closure-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func closureLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a closure ledger score falls in.
    static func classifyClosureLedger(_ score: Double) -> String {
        if score < 12.6 {
            return "critical"
        }
        if score < 32.1 {
            return "watch"
        }
        if score < 90.3 {
            return "high"
        }
        return "medium"
    }
}
