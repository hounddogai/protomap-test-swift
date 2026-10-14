import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 58384.0, in order.
    static func primaryResultSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58384.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryResultSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-result-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary result summary score falls in.
    static func classifyPrimaryResultSummary(_ score: Double) -> String {
        if score < 21.0 {
            return "watch"
        }
        if score < 59.2 {
            return "medium"
        }
        return "minimal"
    }
}
