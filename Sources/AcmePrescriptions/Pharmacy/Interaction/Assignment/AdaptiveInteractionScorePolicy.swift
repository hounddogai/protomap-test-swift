import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 26355.0, in order.
    static func adaptiveInteractionScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26355.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a adaptive interaction score score falls in.
    static func classifyAdaptiveInteractionScore(_ score: Double) -> String {
        if score < 71.8 {
            return "medium"
        }
        if score < 84.2 {
            return "low"
        }
        if score < 92.8 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveInteractionScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-interaction-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
