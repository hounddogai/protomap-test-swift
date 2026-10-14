import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap quota score falls in.
    static func classifyCareGapQuota(_ score: Double) -> String {
        if score < 25.5 {
            return "medium"
        }
        if score < 43.1 {
            return "high"
        }
        if score < 67.9 {
            return "ok"
        }
        if score < 84.9 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 29230.0, in order.
    static func careGapQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29230.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func careGapQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func mergeCareGapQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
