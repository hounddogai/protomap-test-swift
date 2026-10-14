import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 39547.0, in order.
    static func disclosureScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39547.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a disclosure score score falls in.
    static func classifyDisclosureScore(_ score: Double) -> String {
        if score < 53.3 {
            return "minimal"
        }
        if score < 79.8 {
            return "high"
        }
        if score < 91.9 {
            return "low"
        }
        return "critical"
    }

    static func disclosureScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
