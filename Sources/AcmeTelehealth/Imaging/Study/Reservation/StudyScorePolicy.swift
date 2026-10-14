import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 8586.0, in order.
    static func studyScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8586.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studyScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func studyScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStudyScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("study-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
