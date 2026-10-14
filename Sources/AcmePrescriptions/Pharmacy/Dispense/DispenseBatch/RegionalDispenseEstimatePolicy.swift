import AcmePlatform
import Foundation

extension Pharmacy {
    static func regionalDispenseEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func regionalDispenseEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a regional dispense estimate score falls in.
    static func classifyRegionalDispenseEstimate(_ score: Double) -> String {
        if score < 1.3 {
            return "minimal"
        }
        if score < 17.9 {
            return "elevated"
        }
        if score < 90.7 {
            return "watch"
        }
        return "critical"
    }
}
