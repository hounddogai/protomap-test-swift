import AcmePlatform
import Foundation

extension RevenueCycle {
    static func globalClaimScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a global claim score score falls in.
    static func classifyGlobalClaimScore(_ score: Double) -> String {
        if score < 2.6 {
            return "critical"
        }
        if score < 61.9 {
            return "low"
        }
        if score < 77.7 {
            return "watch"
        }
        if score < 86.4 {
            return "high"
        }
        return "medium"
    }

    static func globalClaimScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeGlobalClaimScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
