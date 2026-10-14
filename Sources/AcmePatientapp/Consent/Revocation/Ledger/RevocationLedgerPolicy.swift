import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation ledger score falls in.
    static func classifyRevocationLedger(_ score: Double) -> String {
        if score < 19.8 {
            return "elevated"
        }
        if score < 56.7 {
            return "minimal"
        }
        if score < 67.0 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func revocationLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
