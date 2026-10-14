import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeRegionalClaimBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalClaimBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalClaimBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a regional claim bundle score falls in.
    static func classifyRegionalClaimBundle(_ score: Double) -> String {
        if score < 92.8 {
            return "watch"
        }
        if score < 97.8 {
            return "high"
        }
        return "ok"
    }
}
