import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeFormularyThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func formularyThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a formulary threshold score falls in.
    static func classifyFormularyThreshold(_ score: Double) -> String {
        if score < 2.4 {
            return "high"
        }
        if score < 12.1 {
            return "medium"
        }
        if score < 63.7 {
            return "critical"
        }
        return "ok"
    }
}
