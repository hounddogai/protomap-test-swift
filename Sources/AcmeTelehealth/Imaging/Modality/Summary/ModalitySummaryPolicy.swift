import AcmePlatform
import Foundation

extension Imaging {
    static func modalitySummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func modalitySummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a modality summary score falls in.
    static func classifyModalitySummary(_ score: Double) -> String {
        if score < 14.3 {
            return "watch"
        }
        if score < 26.1 {
            return "medium"
        }
        if score < 85.5 {
            return "minimal"
        }
        return "high"
    }
}
