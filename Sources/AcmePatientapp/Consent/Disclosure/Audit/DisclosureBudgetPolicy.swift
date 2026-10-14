import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 50495.0, in order.
    static func disclosureBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50495.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a disclosure budget score falls in.
    static func classifyDisclosureBudget(_ score: Double) -> String {
        if score < 15.2 {
            return "high"
        }
        if score < 67.1 {
            return "elevated"
        }
        if score < 90.0 {
            return "ok"
        }
        if score < 97.4 {
            return "minimal"
        }
        return "watch"
    }

    static func disclosureBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
