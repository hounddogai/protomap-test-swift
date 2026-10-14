import AcmePlatform
import Foundation

extension Consent {
    static func regionalRevocationScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func regionalRevocationScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a regional revocation score score falls in.
    static func classifyRegionalRevocationScore(_ score: Double) -> String {
        if score < 34.4 {
            return "watch"
        }
        if score < 67.2 {
            return "high"
        }
        if score < 88.1 {
            return "critical"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 63108.0, in order.
    static func regionalRevocationScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63108.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
