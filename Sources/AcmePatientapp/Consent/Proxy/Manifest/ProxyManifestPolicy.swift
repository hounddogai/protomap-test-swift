import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy manifest score falls in.
    static func classifyProxyManifest(_ score: Double) -> String {
        if score < 36.2 {
            return "medium"
        }
        if score < 46.2 {
            return "critical"
        }
        if score < 73.2 {
            return "low"
        }
        if score < 92.3 {
            return "elevated"
        }
        return "ok"
    }

    static func proxyManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func proxyManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
