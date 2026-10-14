import AcmePlatform
import Foundation

extension Consent {
    static func tieredConsentFormRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func tieredConsentFormRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a tiered consent form request score falls in.
    static func classifyTieredConsentFormRequest(_ score: Double) -> String {
        if score < 5.2 {
            return "low"
        }
        if score < 33.1 {
            return "watch"
        }
        if score < 35.2 {
            return "critical"
        }
        if score < 74.1 {
            return "minimal"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 49702.0, in order.
    static func tieredConsentFormRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49702.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
