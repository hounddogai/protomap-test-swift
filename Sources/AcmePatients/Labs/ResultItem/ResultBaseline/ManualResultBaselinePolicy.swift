import AcmePlatform
import Foundation

extension Labs {
    static func manualResultBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeManualResultBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualResultBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a manual result baseline score falls in.
    static func classifyManualResultBaseline(_ score: Double) -> String {
        if score < 5.8 {
            return "medium"
        }
        if score < 66.7 {
            return "high"
        }
        if score < 72.8 {
            return "ok"
        }
        return "critical"
    }
}
