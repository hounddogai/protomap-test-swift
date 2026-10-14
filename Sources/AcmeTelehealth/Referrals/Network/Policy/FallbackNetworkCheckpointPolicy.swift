import AcmePlatform
import Foundation

extension Referrals {
    static func fallbackNetworkCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeFallbackNetworkCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a fallback network checkpoint score falls in.
    static func classifyFallbackNetworkCheckpoint(_ score: Double) -> String {
        if score < 33.4 {
            return "minimal"
        }
        if score < 83.5 {
            return "elevated"
        }
        return "ok"
    }
}
