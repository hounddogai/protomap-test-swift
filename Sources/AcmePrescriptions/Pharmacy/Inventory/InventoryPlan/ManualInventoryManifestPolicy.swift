import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualInventoryManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual inventory manifest score falls in.
    static func classifyManualInventoryManifest(_ score: Double) -> String {
        if score < 55.5 {
            return "ok"
        }
        if score < 60.2 {
            return "watch"
        }
        if score < 64.0 {
            return "medium"
        }
        if score < 74.3 {
            return "low"
        }
        return "high"
    }

    static func mergeManualInventoryManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
