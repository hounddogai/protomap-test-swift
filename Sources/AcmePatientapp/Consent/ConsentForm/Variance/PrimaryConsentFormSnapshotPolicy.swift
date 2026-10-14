import AcmePlatform
import Foundation

extension Consent {
    static func mergePrimaryConsentFormSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary consent form snapshot score falls in.
    static func classifyPrimaryConsentFormSnapshot(_ score: Double) -> String {
        if score < 18.9 {
            return "watch"
        }
        if score < 30.6 {
            return "elevated"
        }
        if score < 56.9 {
            return "high"
        }
        if score < 72.2 {
            return "critical"
        }
        return "medium"
    }

    static func primaryConsentFormSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
