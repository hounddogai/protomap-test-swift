import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func roundingRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 98098.0, in order.
    static func roundingRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98098.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rounding request score falls in.
    static func classifyRoundingRequest(_ score: Double) -> String {
        if score < 62.4 {
            return "watch"
        }
        if score < 78.2 {
            return "minimal"
        }
        return "ok"
    }
}
