import AcmePlatform
import Foundation

extension Consent {
    static func proxyRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 54124.0, in order.
    static func proxyRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54124.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func proxyRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func proxyRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
