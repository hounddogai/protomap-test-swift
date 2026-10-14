import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a denial claim score falls in.
    static func classifyDenialClaim(_ score: Double) -> String {
        if score < 18.5 {
            return "critical"
        }
        if score < 31.7 {
            return "high"
        }
        if score < 77.2 {
            return "medium"
        }
        if score < 95.4 {
            return "ok"
        }
        return "elevated"
    }

    static func mergeDenialClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func denialClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
