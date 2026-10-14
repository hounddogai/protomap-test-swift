import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 33660.0, in order.
    static func pendingSkillMixScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33660.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingSkillMixScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-skill-mix-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
