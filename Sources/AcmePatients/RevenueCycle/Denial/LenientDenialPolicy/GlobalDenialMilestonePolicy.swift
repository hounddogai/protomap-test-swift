import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeGlobalDenialMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalDenialMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a global denial milestone score falls in.
    static func classifyGlobalDenialMilestone(_ score: Double) -> String {
        if score < 43.7 {
            return "elevated"
        }
        if score < 73.1 {
            return "minimal"
        }
        if score < 82.2 {
            return "watch"
        }
        if score < 88.3 {
            return "medium"
        }
        return "high"
    }
}
