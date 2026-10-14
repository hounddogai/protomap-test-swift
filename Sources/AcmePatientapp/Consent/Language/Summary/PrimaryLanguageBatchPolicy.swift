import AcmePlatform
import Foundation

extension Consent {
    static func primaryLanguageBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a primary language batch score falls in.
    static func classifyPrimaryLanguageBatch(_ score: Double) -> String {
        if score < 18.2 {
            return "high"
        }
        if score < 39.1 {
            return "low"
        }
        if score < 69.5 {
            return "ok"
        }
        if score < 83.8 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 27969.0, in order.
    static func primaryLanguageBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27969.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
