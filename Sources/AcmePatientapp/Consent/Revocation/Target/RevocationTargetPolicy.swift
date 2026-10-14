import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation target score falls in.
    static func classifyRevocationTarget(_ score: Double) -> String {
        if score < 54.4 {
            return "minimal"
        }
        if score < 77.9 {
            return "critical"
        }
        if score < 80.5 {
            return "medium"
        }
        if score < 96.2 {
            return "low"
        }
        return "ok"
    }

    static func mergeRevocationTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
