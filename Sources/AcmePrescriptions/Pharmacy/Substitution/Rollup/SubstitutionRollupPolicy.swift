import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a substitution rollup score falls in.
    static func classifySubstitutionRollup(_ score: Double) -> String {
        if score < 5.7 {
            return "low"
        }
        if score < 97.2 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSubstitutionRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("substitution-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 10260.0, in order.
    static func substitutionRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10260.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func substitutionRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
