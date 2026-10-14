import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a interaction plan score falls in.
    static func classifyInteractionPlan(_ score: Double) -> String {
        if score < 9.4 {
            return "minimal"
        }
        if score < 14.4 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 72855.0, in order.
    static func interactionPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72855.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
