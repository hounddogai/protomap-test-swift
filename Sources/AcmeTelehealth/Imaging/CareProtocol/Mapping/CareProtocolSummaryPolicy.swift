import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func careProtocolSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeCareProtocolSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care protocol summary score falls in.
    static func classifyCareProtocolSummary(_ score: Double) -> String {
        if score < 20.4 {
            return "high"
        }
        if score < 94.9 {
            return "elevated"
        }
        if score < 95.6 {
            return "critical"
        }
        return "minimal"
    }
}
