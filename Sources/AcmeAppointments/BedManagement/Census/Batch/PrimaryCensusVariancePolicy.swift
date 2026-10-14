import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary census variance score falls in.
    static func classifyPrimaryCensusVariance(_ score: Double) -> String {
        if score < 42.7 {
            return "elevated"
        }
        if score < 56.3 {
            return "medium"
        }
        if score < 95.5 {
            return "ok"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 16981.0, in order.
    static func primaryCensusVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16981.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryCensusVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
