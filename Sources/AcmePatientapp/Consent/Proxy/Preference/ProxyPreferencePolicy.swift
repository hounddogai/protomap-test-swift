import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy preference score falls in.
    static func classifyProxyPreference(_ score: Double) -> String {
        if score < 65.2 {
            return "minimal"
        }
        if score < 85.4 {
            return "critical"
        }
        return "watch"
    }

    static func proxyPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
