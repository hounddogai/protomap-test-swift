import AcmePlatform
import Foundation

extension Referrals {
    static func mergeLenientNetworkSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient network snapshot score falls in.
    static func classifyLenientNetworkSnapshot(_ score: Double) -> String {
        if score < 68.7 {
            return "medium"
        }
        if score < 85.4 {
            return "minimal"
        }
        if score < 93.3 {
            return "ok"
        }
        return "high"
    }

    static func lenientNetworkSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
