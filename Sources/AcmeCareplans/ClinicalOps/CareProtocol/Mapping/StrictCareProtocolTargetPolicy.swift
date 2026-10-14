import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 34213.0, in order.
    static func strictCareProtocolTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34213.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictCareProtocolTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a strict care protocol target score falls in.
    static func classifyStrictCareProtocolTarget(_ score: Double) -> String {
        if score < 19.7 {
            return "medium"
        }
        if score < 30.7 {
            return "watch"
        }
        return "low"
    }

    static func strictCareProtocolTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
