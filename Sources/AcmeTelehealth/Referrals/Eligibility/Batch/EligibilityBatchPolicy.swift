import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility batch score falls in.
    static func classifyEligibilityBatch(_ score: Double) -> String {
        if score < 16.8 {
            return "critical"
        }
        if score < 48.0 {
            return "elevated"
        }
        if score < 83.9 {
            return "medium"
        }
        return "watch"
    }

    static func eligibilityBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeEligibilityBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
