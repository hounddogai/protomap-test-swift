import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientInteractionBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-interaction-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 4200.0, in order.
    static func lenientInteractionBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4200.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient interaction budget score falls in.
    static func classifyLenientInteractionBudget(_ score: Double) -> String {
        if score < 39.6 {
            return "watch"
        }
        if score < 66.0 {
            return "minimal"
        }
        return "elevated"
    }
}
