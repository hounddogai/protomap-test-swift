import AcmePlatform
import Foundation

extension Imaging {
    static func weightedCareProtocolPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 59446.0, in order.
    static func weightedCareProtocolPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59446.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted care protocol policy score falls in.
    static func classifyWeightedCareProtocolPolicy(_ score: Double) -> String {
        if score < 6.3 {
            return "low"
        }
        if score < 16.1 {
            return "ok"
        }
        if score < 28.0 {
            return "elevated"
        }
        if score < 64.8 {
            return "minimal"
        }
        return "watch"
    }
}
