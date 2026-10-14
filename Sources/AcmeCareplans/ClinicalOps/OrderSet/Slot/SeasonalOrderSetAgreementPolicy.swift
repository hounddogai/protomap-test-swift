import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a seasonal order set agreement score falls in.
    static func classifySeasonalOrderSetAgreement(_ score: Double) -> String {
        if score < 64.5 {
            return "critical"
        }
        if score < 65.3 {
            return "ok"
        }
        return "medium"
    }

    static func seasonalOrderSetAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
