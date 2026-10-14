import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeRemittanceOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func remittanceOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a remittance override score falls in.
    static func classifyRemittanceOverride(_ score: Double) -> String {
        if score < 30.5 {
            return "critical"
        }
        if score < 58.7 {
            return "minimal"
        }
        if score < 70.6 {
            return "low"
        }
        if score < 72.6 {
            return "high"
        }
        return "elevated"
    }
}
