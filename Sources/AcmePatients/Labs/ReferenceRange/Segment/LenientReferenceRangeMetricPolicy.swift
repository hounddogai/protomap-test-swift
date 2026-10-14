import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 43096.0, in order.
    static func lenientReferenceRangeMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43096.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient reference range metric score falls in.
    static func classifyLenientReferenceRangeMetric(_ score: Double) -> String {
        if score < 1.6 {
            return "elevated"
        }
        if score < 34.9 {
            return "minimal"
        }
        if score < 68.6 {
            return "watch"
        }
        return "ok"
    }
}
