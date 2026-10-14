import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 16749.0, in order.
    static func defaultProgramBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16749.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultProgramBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a default program baseline score falls in.
    static func classifyDefaultProgramBaseline(_ score: Double) -> String {
        if score < 30.8 {
            return "watch"
        }
        if score < 58.5 {
            return "low"
        }
        return "medium"
    }

    static func defaultProgramBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
