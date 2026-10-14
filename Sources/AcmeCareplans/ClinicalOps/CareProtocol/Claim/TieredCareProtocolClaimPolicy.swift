import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredCareProtocolClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a tiered care protocol claim score falls in.
    static func classifyTieredCareProtocolClaim(_ score: Double) -> String {
        if score < 1.2 {
            return "watch"
        }
        if score < 62.8 {
            return "critical"
        }
        return "elevated"
    }
}
