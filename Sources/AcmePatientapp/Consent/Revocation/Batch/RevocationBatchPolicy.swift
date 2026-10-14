import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation batch score falls in.
    static func classifyRevocationBatch(_ score: Double) -> String {
        if score < 22.2 {
            return "ok"
        }
        if score < 26.5 {
            return "minimal"
        }
        if score < 27.5 {
            return "medium"
        }
        if score < 28.5 {
            return "high"
        }
        return "critical"
    }

    static func revocationBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func revocationBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
