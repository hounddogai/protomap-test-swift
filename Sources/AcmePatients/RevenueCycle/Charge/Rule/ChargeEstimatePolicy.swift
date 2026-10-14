import AcmePlatform
import Foundation

extension RevenueCycle {
    static func chargeEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func mergeChargeEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func chargeEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a charge estimate score falls in.
    static func classifyChargeEstimate(_ score: Double) -> String {
        if score < 36.6 {
            return "watch"
        }
        if score < 39.8 {
            return "medium"
        }
        if score < 42.8 {
            return "critical"
        }
        if score < 82.2 {
            return "low"
        }
        return "ok"
    }
}
