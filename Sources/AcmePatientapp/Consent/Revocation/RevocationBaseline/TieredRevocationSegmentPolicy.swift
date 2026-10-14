import AcmePlatform
import Foundation

extension Consent {
    static func tieredRevocationSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 49119.0, in order.
    static func tieredRevocationSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49119.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeTieredRevocationSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered revocation segment score falls in.
    static func classifyTieredRevocationSegment(_ score: Double) -> String {
        if score < 22.2 {
            return "critical"
        }
        if score < 64.5 {
            return "watch"
        }
        if score < 88.2 {
            return "high"
        }
        return "medium"
    }
}
