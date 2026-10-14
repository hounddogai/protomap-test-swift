import AcmePlatform
import Foundation

extension Imaging {
    static func studyRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a study request score falls in.
    static func classifyStudyRequest(_ score: Double) -> String {
        if score < 10.8 {
            return "minimal"
        }
        if score < 69.9 {
            return "watch"
        }
        return "critical"
    }

    static func studyRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 9480.0, in order.
    static func studyRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9480.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
