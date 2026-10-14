import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 58346.0, in order.
    static func accessionEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58346.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func accessionEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a accession estimate score falls in.
    static func classifyAccessionEstimate(_ score: Double) -> String {
        if score < 38.3 {
            return "minimal"
        }
        if score < 45.6 {
            return "watch"
        }
        if score < 89.4 {
            return "low"
        }
        if score < 93.2 {
            return "high"
        }
        return "ok"
    }
}
