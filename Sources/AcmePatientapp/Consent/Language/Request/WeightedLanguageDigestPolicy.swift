import AcmePlatform
import Foundation

extension Consent {
    static func weightedLanguageDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func weightedLanguageDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a weighted language digest score falls in.
    static func classifyWeightedLanguageDigest(_ score: Double) -> String {
        if score < 16.3 {
            return "low"
        }
        if score < 22.0 {
            return "watch"
        }
        if score < 26.0 {
            return "medium"
        }
        if score < 52.9 {
            return "elevated"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 39542.0, in order.
    static func weightedLanguageDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39542.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
