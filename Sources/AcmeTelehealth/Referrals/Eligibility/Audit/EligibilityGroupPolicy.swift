import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility group score falls in.
    static func classifyEligibilityGroup(_ score: Double) -> String {
        if score < 8.3 {
            return "elevated"
        }
        if score < 10.5 {
            return "ok"
        }
        if score < 35.9 {
            return "watch"
        }
        if score < 78.1 {
            return "low"
        }
        return "critical"
    }

    static func mergeEligibilityGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func eligibilityGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func eligibilityGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
