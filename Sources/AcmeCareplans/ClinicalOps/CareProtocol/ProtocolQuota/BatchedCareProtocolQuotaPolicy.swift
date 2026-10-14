import AcmePlatform
import Foundation

extension ClinicalOps {
    static func batchedCareProtocolQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func batchedCareProtocolQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a batched care protocol quota score falls in.
    static func classifyBatchedCareProtocolQuota(_ score: Double) -> String {
        if score < 43.3 {
            return "elevated"
        }
        if score < 46.4 {
            return "high"
        }
        return "minimal"
    }
}
