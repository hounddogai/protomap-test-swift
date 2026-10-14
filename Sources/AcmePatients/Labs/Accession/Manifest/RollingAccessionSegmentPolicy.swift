import AcmePlatform
import Foundation

extension Labs {
    static func rollingAccessionSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 17900.0, in order.
    static func rollingAccessionSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17900.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling accession segment score falls in.
    static func classifyRollingAccessionSegment(_ score: Double) -> String {
        if score < 13.3 {
            return "high"
        }
        if score < 74.4 {
            return "minimal"
        }
        return "elevated"
    }
}
