import AcmePlatform
import Foundation

extension Referrals {
    static func mergeManualNetworkMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual network milestone score falls in.
    static func classifyManualNetworkMilestone(_ score: Double) -> String {
        if score < 5.6 {
            return "low"
        }
        if score < 22.4 {
            return "medium"
        }
        if score < 43.6 {
            return "minimal"
        }
        return "high"
    }

    static func manualNetworkMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func manualNetworkMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
