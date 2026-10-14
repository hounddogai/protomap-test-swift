import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedTransferEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedTransferEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-transfer-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched transfer entry score falls in.
    static func classifyBatchedTransferEntry(_ score: Double) -> String {
        if score < 29.6 {
            return "critical"
        }
        if score < 76.9 {
            return "minimal"
        }
        return "watch"
    }
}
