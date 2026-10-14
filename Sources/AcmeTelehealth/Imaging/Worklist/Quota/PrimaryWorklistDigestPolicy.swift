import AcmePlatform
import Foundation

extension Imaging {
    static func primaryWorklistDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 68325.0, in order.
    static func primaryWorklistDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68325.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary worklist digest score falls in.
    static func classifyPrimaryWorklistDigest(_ score: Double) -> String {
        if score < 2.6 {
            return "elevated"
        }
        if score < 22.2 {
            return "low"
        }
        if score < 82.4 {
            return "medium"
        }
        return "watch"
    }

    static func primaryWorklistDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
