import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeGlobalDenialManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global denial manifest score falls in.
    static func classifyGlobalDenialManifest(_ score: Double) -> String {
        if score < 50.4 {
            return "elevated"
        }
        if score < 92.4 {
            return "critical"
        }
        return "minimal"
    }

    static func globalDenialManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
