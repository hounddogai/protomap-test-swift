import AcmePlatform
import Foundation

extension Referrals {
    static func batchedEligibilityDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func batchedEligibilityDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a batched eligibility draft score falls in.
    static func classifyBatchedEligibilityDraft(_ score: Double) -> String {
        if score < 11.0 {
            return "high"
        }
        if score < 58.8 {
            return "elevated"
        }
        return "low"
    }

    static func batchedEligibilityDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
