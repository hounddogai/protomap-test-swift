import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a primary accession window score falls in.
    static func classifyPrimaryAccessionWindow(_ score: Double) -> String {
        if score < 79.8 {
            return "low"
        }
        if score < 94.6 {
            return "ok"
        }
        return "watch"
    }

    static func primaryAccessionWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 38936.0, in order.
    static func primaryAccessionWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
