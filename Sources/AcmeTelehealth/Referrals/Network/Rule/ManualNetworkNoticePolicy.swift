import AcmePlatform
import Foundation

extension Referrals {
    static func manualNetworkNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func manualNetworkNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual network notice score falls in.
    static func classifyManualNetworkNotice(_ score: Double) -> String {
        if score < 22.3 {
            return "medium"
        }
        if score < 26.1 {
            return "ok"
        }
        if score < 39.3 {
            return "high"
        }
        return "low"
    }
}
