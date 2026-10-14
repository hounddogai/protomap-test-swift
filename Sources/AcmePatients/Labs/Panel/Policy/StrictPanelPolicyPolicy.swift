import AcmePlatform
import Foundation

extension Labs {
    static func strictPanelPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a strict panel policy score falls in.
    static func classifyStrictPanelPolicy(_ score: Double) -> String {
        if score < 6.4 {
            return "minimal"
        }
        if score < 28.5 {
            return "low"
        }
        if score < 36.8 {
            return "ok"
        }
        if score < 89.7 {
            return "critical"
        }
        return "elevated"
    }

    static func mergeStrictPanelPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictPanelPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
