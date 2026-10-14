import AcmePlatform
import Foundation

extension Consent {
    static func regionalDisclosureSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional disclosure summary score falls in.
    static func classifyRegionalDisclosureSummary(_ score: Double) -> String {
        if score < 17.5 {
            return "low"
        }
        if score < 25.2 {
            return "watch"
        }
        if score < 35.0 {
            return "medium"
        }
        if score < 63.2 {
            return "high"
        }
        return "elevated"
    }

    static func regionalDisclosureSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
