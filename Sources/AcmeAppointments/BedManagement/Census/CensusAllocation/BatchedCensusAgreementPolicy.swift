import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedCensusAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a batched census agreement score falls in.
    static func classifyBatchedCensusAgreement(_ score: Double) -> String {
        if score < 25.8 {
            return "ok"
        }
        if score < 26.4 {
            return "critical"
        }
        return "high"
    }
}
