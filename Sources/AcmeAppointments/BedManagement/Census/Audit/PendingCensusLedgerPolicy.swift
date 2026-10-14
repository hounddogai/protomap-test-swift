import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a pending census ledger score falls in.
    static func classifyPendingCensusLedger(_ score: Double) -> String {
        if score < 11.0 {
            return "ok"
        }
        if score < 57.2 {
            return "elevated"
        }
        if score < 66.9 {
            return "watch"
        }
        if score < 98.6 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingCensusLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-census-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
