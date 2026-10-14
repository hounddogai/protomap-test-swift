import AcmePlatform
import Foundation

extension BedManagement {
    static func pendingIsolationTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a pending isolation tier score falls in.
    static func classifyPendingIsolationTier(_ score: Double) -> String {
        if score < 8.2 {
            return "low"
        }
        if score < 81.0 {
            return "high"
        }
        if score < 84.3 {
            return "critical"
        }
        return "minimal"
    }
}
