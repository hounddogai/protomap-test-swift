import AcmePlatform
import Foundation

extension BedManagement {
    static func legacyDischargePlanAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a legacy discharge plan adjustment score falls in.
    static func classifyLegacyDischargePlanAdjustment(_ score: Double) -> String {
        if score < 43.3 {
            return "high"
        }
        if score < 83.7 {
            return "low"
        }
        if score < 85.2 {
            return "elevated"
        }
        if score < 93.4 {
            return "medium"
        }
        return "critical"
    }
}
