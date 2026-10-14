import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a alert ledger score falls in.
    static func classifyAlertLedger(_ score: Double) -> String {
        if score < 24.8 {
            return "high"
        }
        if score < 33.1 {
            return "low"
        }
        if score < 83.0 {
            return "medium"
        }
        return "critical"
    }

    static func alertLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func alertLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
