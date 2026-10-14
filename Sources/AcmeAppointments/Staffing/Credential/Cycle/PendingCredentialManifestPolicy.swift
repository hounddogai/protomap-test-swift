import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a pending credential manifest score falls in.
    static func classifyPendingCredentialManifest(_ score: Double) -> String {
        if score < 56.0 {
            return "ok"
        }
        if score < 57.2 {
            return "watch"
        }
        if score < 79.6 {
            return "critical"
        }
        return "high"
    }

    static func pendingCredentialManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func mergePendingCredentialManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingCredentialManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
