import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a discharge plan claim score falls in.
    static func classifyDischargePlanClaim(_ score: Double) -> String {
        if score < 26.7 {
            return "watch"
        }
        if score < 32.3 {
            return "minimal"
        }
        if score < 65.1 {
            return "elevated"
        }
        if score < 70.3 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 181.0, in order.
    static func dischargePlanClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 181.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
