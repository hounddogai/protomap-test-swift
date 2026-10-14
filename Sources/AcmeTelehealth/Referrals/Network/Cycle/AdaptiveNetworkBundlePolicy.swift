import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a adaptive network bundle score falls in.
    static func classifyAdaptiveNetworkBundle(_ score: Double) -> String {
        if score < 9.7 {
            return "ok"
        }
        if score < 89.8 {
            return "high"
        }
        return "elevated"
    }

    static func mergeAdaptiveNetworkBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveNetworkBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
