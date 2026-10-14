import AcmePlatform
import Foundation

extension Consent {
    static func consentFormRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a consent form record score falls in.
    static func classifyConsentFormRecord(_ score: Double) -> String {
        if score < 14.5 {
            return "medium"
        }
        if score < 67.5 {
            return "elevated"
        }
        if score < 80.0 {
            return "high"
        }
        if score < 95.4 {
            return "low"
        }
        return "ok"
    }

    static func mergeConsentFormRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func consentFormRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
