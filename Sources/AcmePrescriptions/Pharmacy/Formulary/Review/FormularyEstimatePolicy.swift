import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a formulary estimate score falls in.
    static func classifyFormularyEstimate(_ score: Double) -> String {
        if score < 74.1 {
            return "low"
        }
        if score < 90.0 {
            return "minimal"
        }
        if score < 98.1 {
            return "elevated"
        }
        return "high"
    }

    static func mergeFormularyEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func formularyEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 24385.0, in order.
    static func formularyEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24385.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
