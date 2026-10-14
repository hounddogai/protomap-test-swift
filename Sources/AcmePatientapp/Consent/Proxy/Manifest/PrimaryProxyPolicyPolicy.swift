import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a primary proxy policy score falls in.
    static func classifyPrimaryProxyPolicy(_ score: Double) -> String {
        if score < 16.0 {
            return "critical"
        }
        if score < 99.5 {
            return "medium"
        }
        return "high"
    }

    static func primaryProxyPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
