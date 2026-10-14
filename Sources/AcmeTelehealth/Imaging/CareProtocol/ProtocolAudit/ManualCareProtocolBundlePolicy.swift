import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a manual care protocol bundle score falls in.
    static func classifyManualCareProtocolBundle(_ score: Double) -> String {
        if score < 6.2 {
            return "minimal"
        }
        if score < 98.7 {
            return "high"
        }
        return "critical"
    }

    static func manualCareProtocolBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualCareProtocolBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
