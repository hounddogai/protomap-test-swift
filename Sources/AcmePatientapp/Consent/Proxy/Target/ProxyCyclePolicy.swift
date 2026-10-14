import AcmePlatform
import Foundation

extension Consent {
    static func proxyCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a proxy cycle score falls in.
    static func classifyProxyCycle(_ score: Double) -> String {
        if score < 14.6 {
            return "low"
        }
        if score < 50.6 {
            return "ok"
        }
        return "critical"
    }

    static func proxyCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func mergeProxyCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
