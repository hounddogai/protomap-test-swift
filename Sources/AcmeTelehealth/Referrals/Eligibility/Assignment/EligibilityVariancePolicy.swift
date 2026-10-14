import AcmePlatform
import Foundation

extension Referrals {
    static func mergeEligibilityVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a eligibility variance score falls in.
    static func classifyEligibilityVariance(_ score: Double) -> String {
        if score < 51.1 {
            return "minimal"
        }
        if score < 53.7 {
            return "elevated"
        }
        return "ok"
    }

    static func eligibilityVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
