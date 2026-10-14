import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a float pool profile score falls in.
    static func classifyFloatPoolProfile(_ score: Double) -> String {
        if score < 4.4 {
            return "medium"
        }
        if score < 6.0 {
            return "high"
        }
        if score < 44.1 {
            return "low"
        }
        if score < 70.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 92969.0, in order.
    static func floatPoolProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92969.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
