import AcmePlatform
import Foundation

extension Consent {
    static func seasonalWitnessGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 49238.0, in order.
    static func seasonalWitnessGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49238.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal witness group score falls in.
    static func classifySeasonalWitnessGroup(_ score: Double) -> String {
        if score < 79.6 {
            return "elevated"
        }
        if score < 85.0 {
            return "minimal"
        }
        if score < 99.5 {
            return "high"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalWitnessGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-witness-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
