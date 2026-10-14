import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 20857.0, in order.
    static func skillMixDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20857.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func skillMixDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func skillMixDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
