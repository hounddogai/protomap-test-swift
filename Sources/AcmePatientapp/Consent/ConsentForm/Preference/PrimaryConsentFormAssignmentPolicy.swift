import AcmePlatform
import Foundation

extension Consent {
    static func mergePrimaryConsentFormAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary consent form assignment score falls in.
    static func classifyPrimaryConsentFormAssignment(_ score: Double) -> String {
        if score < 25.1 {
            return "low"
        }
        if score < 55.9 {
            return "watch"
        }
        return "critical"
    }

    static func primaryConsentFormAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
