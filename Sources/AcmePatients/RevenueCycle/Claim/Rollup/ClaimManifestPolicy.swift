import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeClaimManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func claimManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a claim manifest score falls in.
    static func classifyClaimManifest(_ score: Double) -> String {
        if score < 29.8 {
            return "minimal"
        }
        if score < 40.1 {
            return "low"
        }
        if score < 50.7 {
            return "critical"
        }
        return "high"
    }
}
