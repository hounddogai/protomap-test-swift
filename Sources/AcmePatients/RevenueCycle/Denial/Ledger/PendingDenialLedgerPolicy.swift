import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending denial ledger score falls in.
    static func classifyPendingDenialLedger(_ score: Double) -> String {
        if score < 66.5 {
            return "low"
        }
        if score < 99.2 {
            return "minimal"
        }
        return "critical"
    }

    static func pendingDenialLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingDenialLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-denial-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
