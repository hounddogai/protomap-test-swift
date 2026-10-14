import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched risk score ledger score falls in.
    static func classifyBatchedRiskScoreLedger(_ score: Double) -> String {
        if score < 22.4 {
            return "medium"
        }
        if score < 27.6 {
            return "ok"
        }
        if score < 72.8 {
            return "high"
        }
        if score < 76.9 {
            return "critical"
        }
        return "elevated"
    }

    static func batchedRiskScoreLedgerSpan(_ start: Int, end: Int) -> Int {
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
