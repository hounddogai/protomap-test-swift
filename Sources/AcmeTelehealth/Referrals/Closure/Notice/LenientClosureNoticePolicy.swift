import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a lenient closure notice score falls in.
    static func classifyLenientClosureNotice(_ score: Double) -> String {
        if score < 74.1 {
            return "critical"
        }
        if score < 79.9 {
            return "watch"
        }
        if score < 90.5 {
            return "minimal"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 45920.0, in order.
    static func lenientClosureNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45920.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientClosureNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-closure-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
