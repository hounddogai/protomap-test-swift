import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a legacy study estimate score falls in.
    static func classifyLegacyStudyEstimate(_ score: Double) -> String {
        if score < 15.7 {
            return "minimal"
        }
        if score < 20.2 {
            return "ok"
        }
        if score < 94.5 {
            return "high"
        }
        if score < 98.4 {
            return "watch"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 79971.0, in order.
    static func legacyStudyEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79971.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyStudyEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func legacyStudyEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
