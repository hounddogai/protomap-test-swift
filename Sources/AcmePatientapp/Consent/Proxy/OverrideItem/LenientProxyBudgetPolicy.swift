import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a lenient proxy budget score falls in.
    static func classifyLenientProxyBudget(_ score: Double) -> String {
        if score < 1.8 {
            return "elevated"
        }
        if score < 73.5 {
            return "minimal"
        }
        if score < 82.3 {
            return "watch"
        }
        return "medium"
    }

    static func lenientProxyBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func lenientProxyBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeLenientProxyBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
