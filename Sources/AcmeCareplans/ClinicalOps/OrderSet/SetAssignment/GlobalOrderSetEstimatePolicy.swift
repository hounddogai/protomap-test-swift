import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a global order set estimate score falls in.
    static func classifyGlobalOrderSetEstimate(_ score: Double) -> String {
        if score < 53.1 {
            return "watch"
        }
        if score < 76.0 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 89479.0, in order.
    static func globalOrderSetEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89479.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalOrderSetEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
